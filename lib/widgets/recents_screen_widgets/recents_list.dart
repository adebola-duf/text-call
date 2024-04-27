import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:text_call/models/recent.dart';
import 'package:text_call/providers/recents_provider.dart';
import 'package:text_call/utils/utils.dart';
import 'package:text_call/widgets/expandable_list_tile.dart';
import 'package:intl/intl.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:text_call/widgets/filter_dialog.dart';

class RecentsList extends ConsumerStatefulWidget {
  const RecentsList({
    super.key,
    required this.onRecentSelected,
    required this.screen,
  });

  final void Function(Recent selectedRecent) onRecentSelected;
  final Screen screen;

  @override
  ConsumerState<RecentsList> createState() => _RecentsListState();
}

class _RecentsListState extends ConsumerState<RecentsList> {
  final Map<Recent, bool> _expandedBoolsMap = {};
  CallFilters _selectedFilter = CallFilters.allCalls;

  void _changeTileExpandedStatus(Recent recent) {
    setState(() {
      _expandedBoolsMap[recent] = !_expandedBoolsMap[recent]!;
      for (final loopRecent in _expandedBoolsMap.keys) {
        if (loopRecent != recent && _expandedBoolsMap[loopRecent] == true) {
          _expandedBoolsMap[loopRecent] = false;
        }
      }
    });
  }

  String _groupHeaderText(DateTime headerDateTime) {
    if (DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day) ==
        DateTime(
            headerDateTime.year, headerDateTime.month, headerDateTime.day)) {
      return "Today";
    } else if (DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day - 1) ==
        DateTime(
            headerDateTime.year, headerDateTime.month, headerDateTime.day)) {
      return 'Yesterday';
    }
    return DateFormat('d MMMM').format(headerDateTime);
  }

  void _showFilterDialog() async {
    final selectedFilter = await showAdaptiveDialog<CallFilters?>(
      context: context,
      builder: (context) => FilterDialog(currentFilter: _selectedFilter),
    );
    if (selectedFilter == null) {
      return;
    }
    setState(() {
      _selectedFilter = selectedFilter;
    });
  }

  List<Recent> _applyFilter(List<Recent> allRecents) {
    if (_selectedFilter == CallFilters.allCalls) {
      return allRecents;
    }

    if (_selectedFilter == CallFilters.incomingCalls) {
      return allRecents
          .where(
            (element) => [
              RecentCategory.incomingAccepted,
              RecentCategory.incomingMissed,
              RecentCategory.incomingRejected
            ].contains(element.category),
          )
          .toList();
    }
    if (_selectedFilter == CallFilters.unansweredCalls) {
      return allRecents
          .where(
            (element) => [
              RecentCategory.outgoingUnanswered,
            ].contains(element.category),
          )
          .toList();
    }

    if (_selectedFilter == CallFilters.outgoingCalls) {
      return allRecents
          .where(
            (element) => [
              RecentCategory.outgoingAccepted,
              RecentCategory.outgoingUnanswered,
              RecentCategory.outgoingRejected
            ].contains(element.category),
          )
          .toList();
    }

    if (_selectedFilter == CallFilters.missedCalls) {
      return allRecents
          .where(
            (element) => [
              RecentCategory.outgoingUnanswered,
              RecentCategory.incomingMissed
            ].contains(element.category),
          )
          .toList();
    }

    return allRecents
        .where(
          (element) => [
            RecentCategory.outgoingRejected,
            RecentCategory.incomingRejected
          ].contains(element.category),
        )
        .toList();
  }

  Future<void> _refreshRecents() async {
    await ref.read(recentsProvider.notifier).loadRecents();
  }

  @override
  Widget build(BuildContext context) {
    final recentsList = _applyFilter(ref.watch(recentsProvider));

    return Column(
      children: [
        const SizedBox(
          height: 45,
        ),
        const Text(
          'Recents',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
        const SizedBox(
          height: 50,
        ),
        Row(
          children: [
            const Spacer(),
            IconButton(
              onPressed: _showFilterDialog,
              icon: const Icon(Icons.filter_alt),
            ),
            IconButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('callMessage', 'callMessage');
                await prefs.setString('callerPhoneNumber', 'callerPhoneNumber');
                await prefs.setString('callerName', 'callerPhoneNumber');
                await prefs.setString(
                  'backgroundColor',
                  json.encode(
                    {
                      'alpha': 200,
                      'red': 90,
                      'green': 90,
                      'blue': 20,
                    },
                  ),
                );
                createAwesomeNotification(title: 'Bolexyro');
              },
              icon: const Icon(Icons.search),
            ),
            const SizedBox(width: 10),
          ],
        ),
        if (recentsList.isNotEmpty)
          Expanded(
            child: LiquidPullToRefresh(
              color: Theme.of(context).colorScheme.primaryContainer,
              backgroundColor: Colors.white,
              showChildOpacityTransition: false,
              onRefresh: _refreshRecents,
              height: MediaQuery.sizeOf(context).width < 520 ? 120 : 80,
              animSpeedFactor: 2.3,
              springAnimationDurationInMilliseconds: 600,
              child: GroupedListView(
                physics: const AlwaysScrollableScrollPhysics(),
                useStickyGroupSeparators: true,
                stickyHeaderBackgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                elements: recentsList,
                groupBy: (recentN) => DateTime(recentN.callTime.year,
                    recentN.callTime.month, recentN.callTime.day),
                groupSeparatorBuilder: (DateTime groupHeaderDateTime) =>
                    Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _groupHeaderText(groupHeaderDateTime),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                order: GroupedListOrder.DESC,
                itemComparator: (element1, element2) =>
                    element1.callTime.compareTo(element2.callTime),
                itemBuilder: (context, recentN) {
                  _expandedBoolsMap[recentN] =
                      _expandedBoolsMap.containsKey(recentN)
                          ? _expandedBoolsMap[recentN]!
                          : false;

                  return Slidable(
                    startActionPane: ActionPane(
                      motion: const BehindMotion(),
                      children: [
                        CustomSlidableAction(
                          onPressed: (context) {
                            showMessageWriterModalSheet(
                                context: context,
                                calleePhoneNumber: recentN.contact.phoneNumber,
                                calleeName: recentN.contact.name);
                          },
                          backgroundColor: const Color(0xFF21B7CA),
                          foregroundColor: Colors.white,
                          child: SvgPicture.asset(
                            'assets/icons/message-ring.svg',
                            height: 30,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      ],
                    ),
                    child: widget.screen == Screen.phone
                        ? ExpandableListTile(
                            tileOnTapped: () {
                              _changeTileExpandedStatus(recentN);
                            },
                            isExpanded: _expandedBoolsMap[recentN]!,
                            leading: recentCategoryIconMap[recentN.category]!,
                            trailing: Text(
                              DateFormat.Hm().format(recentN.callTime),
                            ),
                            title: Text(recentN.contact.name),
                            expandedContent: Column(
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Mobile ${recentN.contact.localPhoneNumber}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(recntCategoryStringMap[recentN.category]!),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        showMessageWriterModalSheet(
                                          calleeName: recentN.contact.name,
                                          calleePhoneNumber:
                                              recentN.contact.phoneNumber,
                                          context: context,
                                        );
                                      },
                                      icon: SvgPicture.asset(
                                        'assets/icons/message-ring.svg',
                                        height: 24,
                                        colorFilter: ColorFilter.mode(
                                          Theme.of(context).iconTheme.color!,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        widget.onRecentSelected(recentN);
                                      },
                                      icon: Icon(
                                        Icons.info_outlined,
                                        color:
                                            Theme.of(context).iconTheme.color!,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              ListTile(
                                leading:
                                    recentCategoryIconMap[recentN.category]!,
                                trailing: Text(
                                  DateFormat.Hm().format(recentN.callTime),
                                ),
                                title: Text(recentN.contact.name),
                                onTap: () => widget.onRecentSelected(recentN),
                              ),
                              const Divider(
                                indent: 45,
                                endIndent: 15,
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ),
        if (recentsList.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start calling to see your history.',
                    textAlign: TextAlign.center,
                  ),
                  Icon(
                    Icons.history,
                    size: 110,
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 100,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
