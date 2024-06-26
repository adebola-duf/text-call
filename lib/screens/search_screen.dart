import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:text_call/models/contact.dart';
import 'package:text_call/providers/contacts_provider.dart';
import 'package:text_call/utils/constants.dart';
import 'package:text_call/utils/utils.dart';
import 'package:text_call/widgets/contacts_screen_widgets/contact_avatar_circle.dart';
import 'package:text_call/widgets/contacts_screen_widgets/contact_details_pane.dart';
import 'package:text_call/widgets/contacts_screen_widgets/contact_letter_avatar.dart';
import 'package:text_call/widgets/expandable_list_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Contact? _currentContact;

  void _setCurrentContact(Contact selectedContact) {
    setState(() {
      _currentContact = selectedContact;
    });
  }

  void _goToPage(Contact selectedContact) {
    const stackPadding = EdgeInsets.symmetric(horizontal: 10);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SafeArea(
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new),
              ),
            ),
            resizeToAvoidBottomInset: false,
            body: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: ContactDetailsPane(
                contact: selectedContact,
                stackContainerWidths:
                    MediaQuery.sizeOf(context).width - stackPadding.horizontal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark ? true : false;
    final bool isPhone =
        MediaQuery.sizeOf(context).width < kTabletWidth ? true : false;
    final activeContent = _currentContact == null
        ? const Padding(
            padding: EdgeInsets.all(10.0),
            child: Center(
              child: Text(
                'Select a contact from the list on the left',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          )
        : ContactDetailsPane(
            key: ObjectKey(_currentContact),
            contact: _currentContact,
            stackContainerWidths: MediaQuery.sizeOf(context).width * .425,
          );
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text('Search'),
      ),
      body: SafeArea(
        child: isPhone
            ? MainSearchWidget(
                onContactSelected: _goToPage,
              )
            : Row(
                children: [
                  Expanded(
                    child: MainSearchWidget(
                      onContactSelected: _setCurrentContact,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.only(top: 40),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? makeColorLighter(
                                Theme.of(context).primaryColor, 15)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: activeContent,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class MainSearchWidget extends ConsumerStatefulWidget {
  const MainSearchWidget({
    super.key,
    required this.onContactSelected,
  });

  final void Function(Contact contact) onContactSelected;
  @override
  ConsumerState<MainSearchWidget> createState() => _MainSearchWidgetState();
}

class _MainSearchWidgetState extends ConsumerState<MainSearchWidget> {
  final List<bool> _expandedBoolsList = [];
  String currentSeachText = '';
  List<Contact> contacts = [];
  late final TextEditingController _searchController;

  @override
  void initState() {
    _searchController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeTileExpandedStatus(int index) {
    setState(() {
      _expandedBoolsList[index] = !_expandedBoolsList[index];
      for (int i = 0; i < _expandedBoolsList.length; i++) {
        if (i != index && _expandedBoolsList[i] == true) {
          _expandedBoolsList[i] = false;
        }
      }
    });
  }

  void updateContacts() {
    setState(
      () {
        contacts = ref
            .read(contactsProvider)
            .where(
              (eachContact) =>
                  eachContact.name.toLowerCase().contains(currentSeachText),
            )
            .toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = MediaQuery.sizeOf(context).width < kTabletWidth;
    return Column(
      children: [
        Hero(
          tag: 'searchBarTag',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: SizedBox(
              height: 66,
              child: Card(
                elevation:
                    Theme.of(context).brightness == Brightness.dark ? 10 : 3,
                color: makeColorLighter(
                    Theme.of(context).colorScheme.surfaceContainer,
                    Theme.of(context).brightness == Brightness.dark ? 10 : -10),
                shape: const StadiumBorder(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 27.0),
                    child: Row(
                      children: [
                        const Icon(Icons.search),
                        const SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration:
                                const InputDecoration(border: InputBorder.none),
                            onChanged: (_) {
                              currentSeachText = _.toLowerCase();
                              if (currentSeachText == '') {
                                setState(() {
                                  contacts = [];
                                });
                                return;
                              }
                              updateContacts();
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _searchController.text = '',
                          child: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: 12,
              right: 12,
              left: 12,
              bottom: MediaQuery.viewInsetsOf(context).vertical == 0
                  ? 12
                  : MediaQuery.viewInsetsOf(context).vertical + 12,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? makeColorLighter(Theme.of(context).primaryColor, 15)
                      : Colors.grey[200],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    contacts.length,
                    (index) {
                      final contactN = contacts[index];
                      final specialChStartIndex =
                          contactN.name.toLowerCase().indexOf(currentSeachText);

                      final specialChEndIndex =
                          specialChStartIndex + currentSeachText.length;
                      _expandedBoolsList.add(false);
                      return ExpandableListTile(
                        justARegularListTile: !isPhone,
                        isExpanded: _expandedBoolsList[index],
                        title: RichText(
                          text: TextSpan(
                            text:
                                contactN.name.substring(0, specialChStartIndex),
                            style: DefaultTextStyle.of(context).style,
                            children: <TextSpan>[
                              TextSpan(
                                text: contactN.name.substring(
                                    specialChStartIndex, specialChEndIndex),
                                style: const TextStyle(color: Colors.blue),
                              ),
                              TextSpan(
                                text:
                                    contactN.name.substring(specialChEndIndex),
                              ),
                            ],
                          ),
                        ),
                        leading: isPhone
                            ? GestureDetector(
                                onTap: () {
                                  widget.onContactSelected(contactN);
                                },
                                child: contactN.imagePath != null
                                    ? Hero(
                                        tag: contactN.phoneNumber,
                                        child: ContactAvatarCircle(
                                          avatarRadius: 20,
                                          imagePath: contactN.imagePath,
                                        ),
                                      )
                                    : ContactLetterAvatar(
                                        contactName: contactN.name),
                              )
                            : contactN.imagePath != null
                                ? ContactAvatarCircle(
                                    avatarRadius: 20,
                                    imagePath: contactN.imagePath,
                                  )
                                : ContactLetterAvatar(
                                    contactName: contactN.name),
                        tileOnTapped: () {
                          if (isPhone) {
                            _changeTileExpandedStatus(index);
                            return;
                          }
                          widget.onContactSelected(contactN);
                        },
                        expandedContent: Column(
                          children: [
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              'Mobile ${contactN.localPhoneNumber}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    showMessageWriterModalSheet(
                                      calleeName: contactN.name,
                                      calleePhoneNumber: contactN.phoneNumber,
                                      context: context,
                                    );
                                  },
                                  icon: SvgPicture.asset(
                                    'assets/icons/message-ring.svg',
                                    height: kIconHeight,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).iconTheme.color!,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    widget.onContactSelected(contactN);
                                  },
                                  icon: Icon(
                                    Icons.info_outlined,
                                    color: Theme.of(context).iconTheme.color!,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
