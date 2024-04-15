import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:text_call/models/contact.dart';
import 'package:text_call/providers/contacts_provider.dart';
import 'package:text_call/utils/utils.dart';
import 'package:text_call/widgets/contacts_screen_widgets/add_contact.dart';
import 'package:text_call/widgets/expandable_list_tile.dart';

class ContactsList extends ConsumerStatefulWidget {
  const ContactsList({
    super.key,
    required this.onContactSelected,
  });

  final void Function(Contact selectedContact) onContactSelected;

  @override
  ConsumerState<ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends ConsumerState<ContactsList> {
  final List<bool> _listExpandedBools = [];

  void _showAddContactDialog(context) async {
    showAdaptiveDialog(
      context: context,
      builder: (context) {
        return AddContact();
      },
    );
  }

  void _changeTileExpandedStatus(index) {
    setState(() {
      _listExpandedBools[index] = !_listExpandedBools[index];
      for (int i = 0; i < _listExpandedBools.length; i++) {
        if (i != index && _listExpandedBools[i] == true) {
          _listExpandedBools[i] = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Contact> contactsList = ref.watch(contactsProvider);
    // final contactsList = [
    //   const Contact(name: 'Bolexyro', phoneNumber: '09027929326'),
    //   const Contact(name: 'Mom', phoneNumber: '07034744820'),
    // ];

    return Column(
      children: [
        const Text(
          'Phone',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            '${contactsList.length} contacts with phone number',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(
          height: 70,
        ),
        Row(
          children: [
            const Spacer(),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                _showAddContactDialog(context);
              },
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
            const SizedBox(width: 10),
          ],
        ),
        if (contactsList.isEmpty)
          const Center(
            child: Text("You have no contacts"),
          ),
        if (contactsList.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                Contact contactN = contactsList[index];
                _listExpandedBools.add(false);
                return Slidable(
                  startActionPane: ActionPane(
                    motion: const BehindMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          showMessageWriterModalSheet(
                              context: context,
                              calleePhoneNumber: contactN.phoneNumber,
                              calleeName: contactN.name);
                        },
                        backgroundColor: const Color(0xFF21B7CA),
                        foregroundColor: Colors.white,
                        icon: Icons.message,
                        label: 'Call',
                      ),
                      SlidableAction(
                        onPressed: (context) {},
                        backgroundColor: const Color(0xFFFE4A49),
                        foregroundColor: Colors.white,
                        icon: Icons.close,
                        label: 'Cancel',
                      ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: const BehindMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          ref
                              .read(contactsProvider.notifier)
                              .deleteContact(contactN.phoneNumber);
                        },
                        backgroundColor: const Color(0xFFFE4A49),
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: ExpandableListTile(
                    isExpanded: _listExpandedBools[index],
                    title: Text(contactN.name),
                    leading: CircleAvatar(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.deepPurple,
                              Colors.blue,
                            ],
                          ),
                        ),
                        child: Text(
                          contactN.name[0],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 25),
                        ),
                      ),
                    ),
                    tileOnTapped: () {
                      _changeTileExpandedStatus(index);
                    },
                    expandedContent: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Mobile ${contactN.localPhoneNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('Incoming Call'),
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
                              icon: const Icon(Icons.message),
                            ),
                            IconButton(
                              onPressed: () {
                                widget.onContactSelected(contactN);
                              },
                              icon: const Icon(Icons.info_outlined),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              itemCount: contactsList.length,
            ),
          ),
      ],
    );
  }
}
