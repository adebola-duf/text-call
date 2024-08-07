import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:text_call/models/recent.dart';
import 'package:text_call/providers/recents_provider.dart';
import 'package:text_call/utils/constants.dart';
import 'package:text_call/utils/utils.dart';
import 'package:text_call/widgets/expandable_list_tile.dart';
import 'package:intl/intl.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:text_call/widgets/dialogs/filter_dialog.dart';

class RecentsList extends ConsumerStatefulWidget {
  const RecentsList({
    super.key,
    required this.onRecentSelected,
    required this.screen,
    required this.scaffoldKey,
  });

  final void Function(Recent? selectedRecent) onRecentSelected;
  final Screen screen;
  final GlobalKey<ScaffoldState> scaffoldKey;

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
              RecentCategory.incomingIgnored,
              RecentCategory.incomingRejected
            ].contains(element.category),
          )
          .toList();
    }
    if (_selectedFilter == CallFilters.outgoingCalls) {
      return allRecents
          .where(
            (element) => [
              RecentCategory.outgoingAccepted,
              RecentCategory.outgoingIgnored,
              RecentCategory.outgoingUnreachable,
              RecentCategory.outgoingRejected
            ].contains(element.category),
          )
          .toList();
    }
    if (_selectedFilter == CallFilters.ignoredCalls) {
      return allRecents
          .where(
            (element) => [
              RecentCategory.outgoingIgnored,
              RecentCategory.incomingIgnored,
            ].contains(element.category),
          )
          .toList();
    }

    if (_selectedFilter == CallFilters.acceptedCalls) {
      return allRecents
          .where(
            (element) => [
              RecentCategory.outgoingAccepted,
              RecentCategory.incomingAccepted
            ].contains(element.category),
          )
          .toList();
    }
    if (_selectedFilter == CallFilters.unreachableCalls) {
      return allRecents
          .where(
            (element) => [
              RecentCategory.outgoingUnreachable,
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
    widget.onRecentSelected(null);
    await ref.read(recentsProvider.notifier).loadRecents();
  }

  @override
  Widget build(BuildContext context) {
    final recentsList = _applyFilter(ref.watch(recentsProvider));

    return Column(
      children: [
        Stack(
          children: [
            Container(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () {
                  widget.scaffoldKey.currentState!.openDrawer();
                },
                icon: SvgPicture.asset(
                  'assets/icons/hamburger-menu.svg',
                  height: 30,
                  colorFilter: ColorFilter.mode(
                      Theme.of(context).iconTheme.color ?? Colors.grey,
                      BlendMode.srcIn),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Text(
                  'Recents',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge!
                      .copyWith(fontWeight: FontWeight.bold),
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
                    // IconButton(
                    //   onPressed: () async {
                    // final prefs = await SharedPreferences.getInstance();
                    // await prefs.setString('callMessage',
                    //     'callMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessagecallMessage');
                    // await prefs.setString(
                    //     'callerPhoneNumber', '+2349027929326');
                    // await prefs.setString(
                    //     'callerName', 'callerPhoneNumber');
                    // await prefs.setString(
                    //   'backgroundColor',
                    //   json.encode(
                    //     {
                    //       'alpha': 200,
                    //       'red': 90,
                    //       'green': 90,
                    //       'blue': 20,
                    //     },
                    //   ),
                    // );
                    // createAwesomeNotification(
                    //   title: 'Bolexyro',
                    //   notificationPurpose: NotificationPurpose.forCall,
                    // );
                    // },
                    //   icon: const Icon(Icons.search),
                    // ),
                    const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 10)
              ],
            )
          ],
        ),
        if (recentsList.isEmpty)
          Expanded(
            child: LiquidPullToRefresh(
              color: Theme.of(context).colorScheme.primaryContainer,
              backgroundColor: Colors.white,
              showChildOpacityTransition: false,
              onRefresh: _refreshRecents,
              height: MediaQuery.sizeOf(context).width < 520 ? 120 : 80,
              animSpeedFactor: 2.3,
              springAnimationDurationInMilliseconds: 600,
              child: ListView(
                children: const [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 60,
                      ),
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
                ],
              ),
            ),
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
                    groupHeaderText(groupHeaderDateTime),
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
                              calleeName: recentN.contact.name,
                              complexMessage: recentN.complexMessage,
                              regularMessage: recentN.regularMessage,
                              canBeViewed: recentN.canBeViewed,
                            );
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
                    endActionPane: recentN.recentIsAContact
                        ? null
                        : ActionPane(
                            motion: const BehindMotion(),
                            children: [
                              CustomSlidableAction(
                                onPressed: (context) {
                                  showAddContactDialog(context,
                                      phoneNumber: recentN.contact.phoneNumber);
                                },
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                child: const Icon(Icons.person_add),
                              ),
                            ],
                          ),
                    child: widget.screen == Screen.phone
                        ? ExpandableListTile(
                            justARegularListTile: false,
                            tileOnTapped: () {
                              _changeTileExpandedStatus(recentN);
                            },
                            isExpanded: _expandedBoolsMap[recentN]!,
                            leading: recentN.category.iconPath == null
                                ? recentN.category.icon!
                                : SvgPicture.asset(
                                    recentN.category.iconPath!,
                                    height: kIconHeight,
                                    colorFilter: ColorFilter.mode(
                                        recentN.category.iconColor,
                                        BlendMode.srcIn),
                                  ),
                            trailing: Text(
                              DateFormat.Hm().format(recentN.callTime),
                            ),
                            title: Text(recentN.contact.name),
                            expandedContent: Column(
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                if (recentN.recentIsAContact)
                                  Text(
                                    'Mobile ${recentN.contact.localPhoneNumber}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                Text(recentN.category.label),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (!recentN.recentIsAContact)
                                      IconButton(
                                        onPressed: () {
                                          showAddContactDialog(context,
                                              phoneNumber:
                                                  recentN.contact.phoneNumber);
                                        },
                                        icon: const Icon(Icons.person_add),
                                      ),
                                    IconButton(
                                      onPressed: () {
                                        showMessageWriterModalSheet(
                                          context: context,
                                          calleeName: recentN.contact.name,
                                          calleePhoneNumber:
                                              recentN.contact.phoneNumber,
                                          complexMessage:
                                              recentN.complexMessage,
                                          regularMessage:
                                              recentN.regularMessage,
                                          canBeViewed: recentN.canBeViewed,
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
                                        if (recentN.canBeViewed) {
                                          widget.onRecentSelected(recentN);
                                          return;
                                        }
                                        if (recentN.accessRequestPending) {
                                          showADialog(
                                            header: 'Alert!!',
                                            body:
                                                'Permission to access the message from ${recentN.contact.name} is already requested and is currently pending.',
                                            context: context,
                                            buttonText: 'OK',
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          );
                                          return;
                                        }
                                        showADialog(
                                          header: 'Alert!!',
                                          body:
                                              'you have to ask ${recentN.contact.name} for permission to see this message since you ${recentN.category == RecentCategory.incomingRejected ? 'rejected' : 'ignored'} the call.',
                                          context: context,
                                          buttonText: 'Send  access request',
                                          onPressed: () {
                                            sendAccessRequest(recentN, ref);
                                            Navigator.of(context).pop();
                                          },
                                        );
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
                                leading: recentN.category.iconPath == null
                                    ? recentN.category.icon!
                                    : SvgPicture.asset(
                                        recentN.category.iconPath!,
                                        height: kIconHeight,
                                        colorFilter: ColorFilter.mode(
                                            recentN.category.iconColor,
                                            BlendMode.srcIn),
                                      ),
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
          )
      ],
    );
  }
}
