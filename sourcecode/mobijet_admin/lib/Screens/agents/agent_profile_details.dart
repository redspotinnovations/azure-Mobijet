import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:thinkcreative_technologies/Configs/db_keys.dart';
import 'package:thinkcreative_technologies/Configs/db_paths.dart';
import 'package:thinkcreative_technologies/Configs/number_limits.dart';
import 'package:thinkcreative_technologies/Configs/optional_constants.dart';
import 'package:thinkcreative_technologies/Localization/language_constants.dart';
import 'package:thinkcreative_technologies/Models/agent_model.dart';
import 'package:thinkcreative_technologies/Models/userapp_settings_model.dart';
import 'package:thinkcreative_technologies/Screens/chat/all_agents_chat.dart';
import 'package:thinkcreative_technologies/Screens/groups/all_groups.dart';
import 'package:thinkcreative_technologies/Screens/networkSensitiveUi/NetworkSensitiveUi.dart';
import 'package:thinkcreative_technologies/Screens/settings/department/all_departments_list.dart';
import 'package:thinkcreative_technologies/Screens/tickets/all_tickets.dart';
import 'package:thinkcreative_technologies/Screens/users/user_notifications.dart';
import 'package:thinkcreative_technologies/Services/my_providers/observer.dart';
import 'package:thinkcreative_technologies/Utils/setStatusBarColor.dart';
import 'package:thinkcreative_technologies/Widgets/CameraGalleryImagePicker/camera_image_gallery_picker.dart';
import 'package:thinkcreative_technologies/Widgets/custom_buttons.dart';
import 'package:thinkcreative_technologies/Widgets/custom_text.dart';
import 'package:thinkcreative_technologies/Services/firebase_services/FirebaseApi.dart';
import 'package:thinkcreative_technologies/Services/my_providers/session_provider.dart';
import 'package:thinkcreative_technologies/Widgets/dialogs/CustomDialog.dart';
import 'package:thinkcreative_technologies/Widgets/dialogs/FormDialog.dart';
import 'package:thinkcreative_technologies/Widgets/dialogs/loadingDialog.dart';
import 'package:thinkcreative_technologies/Widgets/dialogs/uploadMediaWithProgress.dart';
import 'package:thinkcreative_technologies/Widgets/late_load.dart';
import 'package:thinkcreative_technologies/Widgets/my_inkwell.dart';
import 'package:thinkcreative_technologies/Utils/custom_time_formatter.dart';
import 'package:thinkcreative_technologies/Utils/utils.dart';
import 'package:thinkcreative_technologies/Configs/app_constants.dart';
import 'package:thinkcreative_technologies/Configs/my_colors.dart';
import 'package:thinkcreative_technologies/Widgets/Input_box.dart';
import 'package:thinkcreative_technologies/Widgets/my_scaffold.dart';
import 'package:thinkcreative_technologies/Widgets/boxdecoration.dart';
import 'package:thinkcreative_technologies/Widgets/custom_dividers.dart';
import 'package:thinkcreative_technologies/Services/my_providers/firestore_collections_data_admin.dart';
import 'package:thinkcreative_technologies/Utils/page_navigator.dart';
import 'package:thinkcreative_technologies/Utils/tiles.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

class AgentProfileDetails extends StatefulWidget {
  final AgentModel? agent;
  final String? agentID;
  final String currentuserid;
  // final String usertypenamekeyword;
  AgentProfileDetails({
    this.agent,
    this.agentID,
    required this.currentuserid,
    // required this.usertypenamekeyword,
  });
  @override
  _AgentProfileDetailsState createState() => _AgentProfileDetailsState();
}

class _AgentProfileDetailsState extends State<AgentProfileDetails> {
  TextEditingController _controller = new TextEditingController();
  TextEditingController _name = new TextEditingController();
  TextEditingController _pcode = new TextEditingController();
  TextEditingController _pnumber = new TextEditingController();
  TextEditingController _email = new TextEditingController();
  AgentModel? agent;
  CollectionReference colRef =
      FirebaseFirestore.instance.collection(DbPaths.collectionagents);
  UserAppSettingsModel? userAppSettings;
  List myDepartmentList = [];
  @override
  void initState() {
    super.initState();

    if (widget.agent != null) {
      agent = widget.agent!;
    } else {
      fetchAgent();
    }
    fetchUserAppSettings();
  }

  fetchAgent({String? agentId}) async {
    await FirebaseFirestore.instance
        .collection(DbPaths.collectionagents)
        .doc(agentId ?? widget.agentID!)
        .get()
        .then((value) {
      if (value.exists) {
        agent = AgentModel.fromSnapshot(value);
        setState(() {});
      }
    });
  }

  fetchUserAppSettings() {
    FirebaseFirestore.instance
        .collection(DbPaths.userapp)
        .doc(DbPaths.appsettings)
        .get()
        .then((value) {
      userAppSettings = UserAppSettingsModel.fromSnapshot(value);
      myDepartmentList = userAppSettings!.departmentList!
          .where((dept) =>
              dept[Dbkeys.departmentAgentsUIDList].contains(widget.agentID) &&
              dept[Dbkeys.departmentTitle] != "Default")
          .toList();
      setState(() {});
    });
    final observer = Provider.of<Observer>(context, listen: false);
    observer.fetchUserAppSettings(context);
  }

  confirmchangeswitch(
    BuildContext context,
    String? accountSTATUS,
    String userid,
    String? fullname,
    String? photourl,
  ) async {
    final firestore =
        Provider.of<FirestoreDataProviderAGENTS>(context, listen: false);
    final observer = Provider.of<Observer>(context, listen: false);
    ShowSnackbar().close(context: context, scaffoldKey: _scaffoldKey);
    await ShowConfirmWithInputTextDialog().open(
        controller: _controller,
        isshowform: accountSTATUS == Dbkeys.sTATUSpending
            ? false
            : accountSTATUS == Dbkeys.sTATUSblocked
                ? false
                : accountSTATUS == Dbkeys.sTATUSallowed
                    ? true
                    : false,
        context: context,
        subtitle: accountSTATUS == Dbkeys.sTATUSallowed
            ? getTranslatedForCurrentUser(context, 'xxxareyousureblockxxx')
            : accountSTATUS == Dbkeys.sTATUSblocked
                ? getTranslatedForCurrentUser(
                    context, 'xxxareyousureremoveblockkxxx')
                : getTranslatedForCurrentUser(
                    context, 'xxxareyousureapprovekkxxx'),
        title: accountSTATUS == Dbkeys.sTATUSallowed
            ? getTranslatedForCurrentUser(context, 'xxblockuserqxx')
            : accountSTATUS == Dbkeys.sTATUSblocked
                ? getTranslatedForCurrentUser(context, 'xxallowuserqxx')
                : getTranslatedForCurrentUser(context, 'xxapproveuserqxx'),
        rightbtnonpress:
            //  ((accountSTATUS == Dbkeys.sTATUSallowed) &&
            //             (_controller.text.trim().length > 100 ||
            //                 _controller.text.trim().length < 1)) ==
            //         true
            //     ? () {}
            //     :
            AppConstants.isdemomode == true
                ? () {
                    Utils.toast(getTranslatedForCurrentUser(
                        context, 'xxxnotalwddemoxxaccountxx'));
                  }
                : () async {
                    Navigator.pop(context);
                    ShowLoading().open(context: context, key: _keyLoader);
                    await colRef.doc(userid).update({
                      Dbkeys.actionmessage: accountSTATUS ==
                              Dbkeys.sTATUSallowed
                          ? _controller.text.trim().length < 1
                              ? getTranslatedForCurrentUser(
                                  context, 'xxxaccountblockedxxx')
                              : '${getTranslatedForCurrentUser(context, 'xxxaccountblockedforxxx')} ${_controller.text.trim()}.'
                          : accountSTATUS == Dbkeys.sTATUSpending
                              ? getTranslatedForCurrentUser(
                                  context, 'xxxcongratatulationacapprovedxxx')
                              : accountSTATUS == Dbkeys.sTATUSblocked
                                  ? getTranslatedForCurrentUser(context,
                                      'xxxcongratatulationacapprovedxxx')
                                  : getTranslatedForCurrentUser(
                                      context, 'xxxacstatuschangedxxx'),
                      Dbkeys.accountstatus:
                          accountSTATUS == Dbkeys.sTATUSallowed
                              ? Dbkeys.sTATUSblocked
                              : accountSTATUS == Dbkeys.sTATUSblocked
                                  ? Dbkeys.sTATUSallowed
                                  : Dbkeys.sTATUSallowed
                      // Dbkeys.cpnfilter: '$currency${!usrisvisble}',
                    }).then((val) async {
                      await FirebaseApi()
                          .runUPDATEtransactionInDocumentIncrement(
                        context: context,
                        scaffoldkey: _scaffoldKey,
                        // keyloader: _keyLoader2,
                        isshowloader: false,
                        isincremental: true,
                        refdata: FirebaseFirestore.instance
                            .collection(DbPaths.userapp)
                            .doc(DbPaths.docusercount),
                        isshowmsg: false,
                        isusesecondfn: false,
                        incrementalkey: accountSTATUS == Dbkeys.sTATUSallowed
                            ? Dbkeys.totalblockedagents
                            : accountSTATUS == Dbkeys.sTATUSblocked
                                ? Dbkeys.totalapprovedagents
                                : Dbkeys.totalapprovedagents,
                        decrementalkey: accountSTATUS == Dbkeys.sTATUSallowed
                            ? Dbkeys.totalapprovedagents
                            : accountSTATUS == Dbkeys.sTATUSblocked
                                ? Dbkeys.totalblockedagents
                                : Dbkeys.totalpendingagents,
                      )
                          .then((value) async {
                        await FirebaseApi.runTransactionSendNotification(
                            docRef: colRef
                                .doc(agent!.id)
                                .collection(DbPaths.agentnotifications)
                                .doc(DbPaths.agentnotifications),
                            context: context,
                            parentid: "AGENT--${agent!.id}",
                            onErrorFn: (e) {
                              ShowLoading()
                                  .close(context: context, key: _keyLoader);
                              _controller.clear();
                              // print('Erssssror:${observer.isshowerrorlog} $error');
                              ShowSnackbar().open(
                                  context: context,
                                  scaffoldKey: _scaffoldKey,
                                  status: 1,
                                  time: 3,
                                  label: getTranslatedForCurrentUser(
                                          context, 'xxxfailedntryagainxxx') +
                                      e.toString());
                            },
                            onSuccessFn: () async {
                              await FirebaseApi.runTransactionRecordActivity(
                                onErrorFn: (e) {
                                  ShowLoading()
                                      .close(context: context, key: _keyLoader);
                                  _controller.clear();
                                  // print('Erssssror:${observer.isshowerrorlog} $error');
                                  ShowSnackbar().open(
                                      context: context,
                                      scaffoldKey: _scaffoldKey,
                                      status: 1,
                                      time: 3,
                                      label: getTranslatedForCurrentUser(
                                              context,
                                              'xxxfailedntryagainxxx') +
                                          e.toString());
                                },
                                onSuccessFn: () async {
                                  await firestore.updateparticulardocinProvider(
                                      colRef: colRef,
                                      userid: agent!.id,
                                      onfetchDone: (userDoc) async {
                                        setState(() {
                                          agent =
                                              AgentModel.fromSnapshot(userDoc);
                                        });
                                        await ShowLoading().close(
                                            context: context, key: _keyLoader);
                                        _controller.clear();

                                        ShowSnackbar().open(
                                            context: context,
                                            scaffoldKey: _scaffoldKey,
                                            status: 2,
                                            time: 3,
                                            label: accountSTATUS ==
                                                    Dbkeys.sTATUSallowed
                                                ? '${getTranslatedForCurrentUser(context, 'xxxsuccessxxx')}  ${fullname!.toUpperCase()} - ${getTranslatedForCurrentUser(context, 'xxxblockedxxx')}. ${getTranslatedForCurrentUser(context, 'xxxusernotifiedxxx')} '
                                                : accountSTATUS ==
                                                        Dbkeys.sTATUSblocked
                                                    ? '${getTranslatedForCurrentUser(context, 'xxxsuccessxxx')}  ${fullname!.toUpperCase()} - ${getTranslatedForCurrentUser(context, 'xxxapprovedxxx')}. ${getTranslatedForCurrentUser(context, 'xxxusernotifiedxxx')} '
                                                    : '${getTranslatedForCurrentUser(context, 'xxxsuccessxxx')} . ${getTranslatedForCurrentUser(context, 'xxxusernotifiedxxx')} ');
                                      });
                                },
                                parentid: "AGENT--${agent!.id}",
                                postedbyID: widget.currentuserid,
                                title: accountSTATUS == Dbkeys.sTATUSallowed
                                    ? '${getTranslatedForCurrentUser(context, 'xxaccountxx')} ${getTranslatedForCurrentUser(context, 'xxxblockedxxx')}'
                                    : accountSTATUS == Dbkeys.sTATUSpending
                                        ? '${getTranslatedForCurrentUser(context, 'xxaccountxx')} ${getTranslatedForCurrentUser(context, 'xxxapprovedxxx')}'
                                        : accountSTATUS == Dbkeys.sTATUSblocked
                                            ? '${getTranslatedForCurrentUser(context, 'xxaccountxx')} ${getTranslatedForCurrentUser(context, 'xxxapprovedxxx')}'
                                            : getTranslatedForCurrentUser(
                                                context,
                                                'xxxacstatuschangexxx'),
                                plainDesc: accountSTATUS == Dbkeys.sTATUSallowed
                                    ? '$fullname (${getTranslatedForCurrentUser(context, 'xxagentxx')})${getTranslatedForCurrentUser(context, 'xxxtheaccountblockedforxxx')} ${_controller.text.trim()}. ${getTranslatedForCurrentUser(context, 'xxxbyxxx')} ${widget.currentuserid}  '
                                    : accountSTATUS == Dbkeys.sTATUSpending
                                        ? '$fullname (${getTranslatedForCurrentUser(context, 'xxagentxx')}) ${getTranslatedForCurrentUser(context, 'xxaccountxx')} ${getTranslatedForCurrentUser(context, 'xxxapprovedxxx')}. ${getTranslatedForCurrentUser(context, 'xxxbyxxx')} ${widget.currentuserid}   '
                                        : accountSTATUS == Dbkeys.sTATUSblocked
                                            ? '$fullname (${getTranslatedForCurrentUser(context, 'xxagentxx')}) ${getTranslatedForCurrentUser(context, 'xxaccountxx')} ${getTranslatedForCurrentUser(context, 'xxxapprovedxxx')}. ${getTranslatedForCurrentUser(context, 'xxxbyxxx')} ${widget.currentuserid}  '
                                            : '$fullname (${getTranslatedForCurrentUser(context, 'xxagentxx')}) ${getTranslatedForCurrentUser(context, 'xxxacstatuschangexxx')}. ${getTranslatedForCurrentUser(context, 'xxxbyxxx')} ${widget.currentuserid}  ',
                                context: context,
                                isshowloader: false,
                              );
                            },
                            postedbyID: widget.currentuserid,
                            isshowloader: false,
                            title: accountSTATUS == Dbkeys.sTATUSallowed
                                ? '${getTranslatedForCurrentUser(context, 'xxaccountxx')} ${getTranslatedForCurrentUser(context, 'xxxblockedxxx')}'
                                : accountSTATUS == Dbkeys.sTATUSpending
                                    ? '${getTranslatedForCurrentUser(context, 'xxaccountxx')} ${getTranslatedForCurrentUser(context, 'xxxapprovedxxx')}'
                                    : accountSTATUS == Dbkeys.sTATUSblocked
                                        ? '${getTranslatedForCurrentUser(context, 'xxaccountxx')}  ${getTranslatedForCurrentUser(context, 'xxxapprovedxxx')}'
                                        : getTranslatedForCurrentUser(
                                            context, 'xxxacstatuschangexxx'),
                            plainDesc: accountSTATUS == Dbkeys.sTATUSallowed
                                ? _controller.text.trim().length < 1
                                    ? getTranslatedForCurrentUser(
                                        context, 'xxxaccountblockedxxx')
                                    : '${getTranslatedForCurrentUser(context, 'xxxaccountblockedforxxx')} ${_controller.text.trim()}.'
                                : accountSTATUS == Dbkeys.sTATUSpending
                                    ? getTranslatedForCurrentUser(context,
                                        'xxxcongratatulationacapprovedxxx')
                                    : accountSTATUS == Dbkeys.sTATUSblocked
                                        ? getTranslatedForCurrentUser(context,
                                            'xxxcongratatulationacapprovedxxx')
                                        : getTranslatedForCurrentUser(
                                            context, 'xxxacstatuschangedxxx'));
                      });
                    }).catchError((error) {
                      ShowLoading().close(context: context, key: _keyLoader);
                      _controller.clear();
                      // print('Erssssror:${observer.isshowerrorlog} $error');
                      ShowSnackbar().open(
                          context: context,
                          scaffoldKey: _scaffoldKey,
                          status: 1,
                          time: 3,
                          label: observer.isshowerrorlog == false
                              ? getTranslatedForCurrentUser(
                                  context, 'xxxfailedntryagainxxx')
                              : getTranslatedForCurrentUser(
                                      context, 'xxxfailedntryagainxxx') +
                                  error.toString());
                    });
                  });
  }

  updateEmail(String email) {
    ShowFormDialog().open(
        controller: _email,
        maxlength: 50,
        keyboardtype: TextInputType.text,
        iscentrealign: true,
        context: context,
        title: getTranslatedForCurrentUser(context, 'xxxupdatexxxxxx')
            .replaceAll('(####)',
                '${getTranslatedForCurrentUser(context, 'xxemailxx')}'),
        subtitle: getTranslatedForCurrentUser(context, 'xxupdateemailxx'),
        buttontext: getTranslatedForCurrentUser(context, 'xxupdatexx'),
        hinttext: "${getTranslatedForCurrentUser(context, 'xxemailxx')}",
        footerWidget: agent!.email == ""
            ? SizedBox()
            : Padding(
                padding: EdgeInsets.fromLTRB(15, 25, 15, 6),
                child: InkWell(
                  onTap: AppConstants.isdemomode == true
                      ? () {
                          Utils.toast(getTranslatedForCurrentUser(
                              context, 'xxxnotalwddemoxxaccountxx'));
                        }
                      : () async {
                          Navigator.of(context).pop();
                          ShowLoading().open(context: context, key: _keyLoader);

                          await FirebaseFirestore.instance
                              .collection(DbPaths.collectionagents)
                              .doc(agent!.id)
                              .update({
                            Dbkeys.email: "",
                          }).then((value) async {
                            await Utils.sendDirectNotification(
                                title: getTranslatedForEventsAndAlerts(
                                        context, 'xxxxxremovedxxx')
                                    .replaceAll('(####)',
                                        '${getTranslatedForEventsAndAlerts(context, 'xxemailxx')}'),
                                parentID: "AGENT--${agent!.id}",
                                plaindesc: getTranslatedForEventsAndAlerts(
                                    context,
                                    'xxxyopuaccountemailremovedbyadmin'),
                                docRef: FirebaseFirestore.instance
                                    .collection(DbPaths.collectionagents)
                                    .doc(agent!.id)
                                    .collection(DbPaths.agentnotifications)
                                    .doc(DbPaths.agentnotifications),
                                postedbyID: 'Admin');
                            await FirebaseApi.runTransactionRecordActivity(
                              parentid: "AGENT--${agent!.id}",
                              title: getTranslatedForEventsAndAlerts(
                                      context, 'xxxxxremovedxxx')
                                  .replaceAll('(####)',
                                      '${getTranslatedForEventsAndAlerts(context, 'xxemailxx')}'),
                              postedbyID: "sys",
                              onErrorFn: (e) {
                                ShowLoading()
                                    .close(key: _keyLoader, context: context);
                                Utils.toast(
                                    "${getTranslatedForCurrentUser(context, 'xxxfailedntryagainxxx')}  $e");
                              },
                              onSuccessFn: () async {
                                final firestore =
                                    Provider.of<FirestoreDataProviderAGENTS>(
                                        context,
                                        listen: false);
                                firestore.fetchNextData(
                                    Dbkeys.dataTypeAGENTS,
                                    colRef
                                        .orderBy(Dbkeys.joinedOn,
                                            descending: true)
                                        .limit(Numberlimits
                                            .totalDatatoLoadAtOnceFromFirestore),
                                    true);
                                await FirebaseFirestore.instance
                                    .collection(DbPaths.collectionagents)
                                    .doc(agent!.id)
                                    .get()
                                    .then((doc) {
                                  agent = AgentModel.fromSnapshot(doc);
                                  setState(() {});
                                });
                                ShowLoading()
                                    .close(key: _keyLoader, context: context);
                                Utils.toast(
                                  getTranslatedForEventsAndAlerts(
                                          context, 'xxxxxremovedsuccessxxx')
                                      .replaceAll('(####)',
                                          '${getTranslatedForEventsAndAlerts(context, 'xxemailxx')}'),
                                );
                              },
                              styledDesc:
                                  '${getTranslatedForCurrentUser(context, 'xxagentxx')} <bold>${agent!.nickname}</bold> ${getTranslatedForCurrentUser(context, 'xxemailxx')} ${getTranslatedForCurrentUser(context, 'xxremovedbyadminxx')}',
                              plainDesc:
                                  '${getTranslatedForCurrentUser(context, 'xxagentxx')} ${agent!.nickname} ${getTranslatedForCurrentUser(context, 'xxemailxx')} ${getTranslatedForCurrentUser(context, 'xxremovedbyadminxx')} ',
                            );
                          }).catchError((e) {
                            ShowLoading()
                                .close(key: _keyLoader, context: context);
                            Utils.toast(
                                "${getTranslatedForCurrentUser(context, 'xxxfailedntryagainxxx')}  $e");
                          });
                        },
                  child: MtCustomfontBoldSemi(
                    text: getTranslatedForCurrentUser(
                            context, 'xxxremovexxxxxx')
                        .replaceAll('(####)',
                            '${getTranslatedForCurrentUser(context, 'xxemailxx')}'),
                    color: Mycolors.red,
                    fontsize: 15,
                  ),
                ),
              ),
        onpressed: AppConstants.isdemomode == true
            ? () {
                Utils.toast(getTranslatedForCurrentUser(
                    context, 'xxxnotalwddemoxxaccountxx'));
              }
            : () async {
                if (_email.text.trim().length < 1 ||
                    (!_email.text.trim().contains("@") ||
                        !_email.text.trim().contains("."))) {
                  Utils.toast(
                      getTranslatedForCurrentUser(context, 'xxvalidemailxx'));
                } else {
                  if (email == "${_email.text.trim().toLowerCase()}") {
                    Utils.toast(getTranslatedForCurrentUser(
                        context, 'xxxalreadyexistsxxx'));
                  } else {
                    String userid = agent!.id;
                    Navigator.of(context).pop();
                    ShowLoading().open(context: context, key: _keyLoader);

                    await FirebaseFirestore.instance
                        .collection(DbPaths.collectionagents)
                        .where(Dbkeys.email,
                            isEqualTo: "${_email.text.trim().toLowerCase()}")
                        .get()
                        .then((agents) async {
                      if (agents.docs.length != 0) {
                        ShowLoading().close(key: _keyLoader, context: context);
                        Utils.toast(
                          getTranslatedForCurrentUser(
                                  context, 'xxusingemailxxx')
                              .replaceAll('(####)',
                                  '${getTranslatedForCurrentUser(context, 'xxagentxx')} ${agents.docs[0][Dbkeys.nickname]}'),
                        );
                      } else {
                        await FirebaseFirestore.instance
                            .collection(DbPaths.collectioncustomers)
                            .where(Dbkeys.email,
                                isEqualTo:
                                    "${_email.text.trim().toLowerCase()}")
                            .get()
                            .then((doc) async {
                          if (doc.docs.length == 0) {
                            await FirebaseFirestore.instance
                                .collection(DbPaths.collectionagents)
                                .doc(userid)
                                .update({
                              Dbkeys.email: _email.text.trim().toLowerCase(),
                            }).then((value) async {
                              await Utils.sendDirectNotification(
                                  title: getTranslatedForEventsAndAlerts(
                                          context, 'xxxxxxupdatedxx')
                                      .replaceAll('(####)',
                                          '${getTranslatedForEventsAndAlerts(context, 'xxemailxx')}'),
                                  parentID: "AGENT--$userid",
                                  plaindesc: getTranslatedForEventsAndAlerts(
                                          context,
                                          'xxxaccountemailupdatedtoxxx')
                                      .replaceAll('(####)',
                                          '${getTranslatedForEventsAndAlerts(context, '${_email.text.trim().toLowerCase()}')}'),
                                  docRef: FirebaseFirestore.instance
                                      .collection(DbPaths.collectionagents)
                                      .doc(userid)
                                      .collection(DbPaths.agentnotifications)
                                      .doc(DbPaths.agentnotifications),
                                  postedbyID: 'Admin');
                              await FirebaseApi.runTransactionRecordActivity(
                                parentid: "AGENT--$userid",
                                title:
                                    "${getTranslatedForEventsAndAlerts(context, 'xxagentxx')} ${getTranslatedForEventsAndAlerts(context, 'xxxxxxupdatedxx').replaceAll('(####)', '${getTranslatedForEventsAndAlerts(context, 'xxemailxx')}')}",
                                postedbyID: "sys",
                                onErrorFn: (e) {
                                  ShowLoading()
                                      .close(key: _keyLoader, context: context);
                                  Utils.toast(
                                      "${getTranslatedForCurrentUser(context, 'xxxfailedntryagainxxx')}\n $e");
                                },
                                onSuccessFn: () {},
                                styledDesc:
                                    '${getTranslatedForEventsAndAlerts(context, 'xxagentxx')} <bold>${agent!.nickname}</bold> ${getTranslatedForEventsAndAlerts(context, 'xxxaccountemailupdatedtoxxx').replaceAll('(####)', '${"<bold>${_email.text.trim().toLowerCase()}</bold>"}')}',
                                plainDesc:
                                    '${getTranslatedForEventsAndAlerts(context, 'xxagentxx')} ${agent!.nickname} ${getTranslatedForEventsAndAlerts(context, 'xxxaccountemailupdatedtoxxx').replaceAll('(####)', '${_email.text.trim().toLowerCase()}')}',
                              );
                            }).then((value) async {
                              final firestore =
                                  Provider.of<FirestoreDataProviderAGENTS>(
                                      context,
                                      listen: false);
                              firestore.fetchNextData(
                                  Dbkeys.dataTypeAGENTS,
                                  colRef
                                      .orderBy(Dbkeys.joinedOn,
                                          descending: true)
                                      .limit(Numberlimits
                                          .totalDatatoLoadAtOnceFromFirestore),
                                  true);
                              await FirebaseFirestore.instance
                                  .collection(DbPaths.collectionagents)
                                  .doc(userid)
                                  .get()
                                  .then((doc) {
                                agent = AgentModel.fromSnapshot(doc);
                                setState(() {});
                              });

                              ShowLoading()
                                  .close(key: _keyLoader, context: context);

                              Utils.toast(
                                getTranslatedForCurrentUser(
                                        context, 'xxxxxemailsuccessxxx')
                                    .replaceAll('(####)',
                                        '${getTranslatedForCurrentUser(context, 'xxemailxx')}'),
                              );
                            }).catchError((e) {
                              ShowLoading()
                                  .close(key: _keyLoader, context: context);
                              Utils.toast(
                                  "${getTranslatedForCurrentUser(context, 'xxxfailedntryagainxxx')}\n  $e");
                            });
                          } else {
                            ShowLoading()
                                .close(key: _keyLoader, context: context);
                            Utils.toast(
                              getTranslatedForCurrentUser(
                                      context, 'xxusingemailxxx')
                                  .replaceAll('(####)',
                                      '${getTranslatedForCurrentUser(context, 'xxcustomerxx')} ${doc.docs[0][Dbkeys.nickname]}'),
                            );
                          }
                        });
                      }
                    });
                  }
                }
              });
  }

  updateMobile(String phone) {
    ShowFormDialog().open(
        controller: _pcode,
        maxlength: 14,
        keyboardtype: TextInputType.number,
        iscentrealign: true,
        inputFormatter: [
          FilteringTextInputFormatter.allow(RegExp('[0-9]')),
        ],
        controllerExtra: _pnumber,
        context: context,
        title: getTranslatedForCurrentUser(context, 'xxxupdatexxxxxx').replaceAll(
            '(####)',
            '${getTranslatedForCurrentUser(context, 'xxenter_mobilenumberxx')}'),
        subtitle: getTranslatedForCurrentUser(context, 'xxupdatephonexx'),
        buttontext: getTranslatedForCurrentUser(context, 'xxupdatexx'),
        hinttext: getTranslatedForCurrentUser(context, 'xxccxx'),
        hinttextExtra: getTranslatedForCurrentUser(context, 'xxxphonenumberxx'),
        footerWidget: agent!.phone == ""
            ? SizedBox()
            : Padding(
                padding: EdgeInsets.fromLTRB(15, 25, 15, 6),
                child: InkWell(
                  onTap: AppConstants.isdemomode == true
                      ? () {
                          Utils.toast(getTranslatedForCurrentUser(
                              context, 'xxxnotalwddemoxxaccountxx'));
                        }
                      : () async {
                          Navigator.of(context).pop();
                          ShowLoading().open(context: context, key: _keyLoader);

                          await FirebaseFirestore.instance
                              .collection(DbPaths.collectionagents)
                              .doc(agent!.id)
                              .update({
                            Dbkeys.phone: "",
                            Dbkeys.countryCode: "",
                            Dbkeys.phoneRaw: "",
                          }).then((value) async {
                            await Utils.sendDirectNotification(
                                title: getTranslatedForEventsAndAlerts(
                                    context, 'xxphoneremovedxxx'),
                                parentID: "AGENT--${agent!.id}",
                                plaindesc:
                                    "${getTranslatedForEventsAndAlerts(context, 'xxaccountxx')} ${getTranslatedForEventsAndAlerts(context, 'xxphoneremovedxxx')}",
                                docRef: FirebaseFirestore.instance
                                    .collection(DbPaths.collectionagents)
                                    .doc(agent!.id)
                                    .collection(DbPaths.agentnotifications)
                                    .doc(DbPaths.agentnotifications),
                                postedbyID: 'Admin');
                            await FirebaseApi.runTransactionRecordActivity(
                              parentid: "AGENT--${agent!.id}",
                              title:
                                  "${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxphoneremovedxxx')}",
                              postedbyID: "sys",
                              onErrorFn: (e) {
                                ShowLoading()
                                    .close(key: _keyLoader, context: context);
                                Utils.toast(
                                    "${getTranslatedForCurrentUser(context, 'xxfailedxx')} $e");
                              },
                              onSuccessFn: () async {
                                final firestore =
                                    Provider.of<FirestoreDataProviderAGENTS>(
                                        context,
                                        listen: false);
                                firestore.fetchNextData(
                                    Dbkeys.dataTypeAGENTS,
                                    colRef
                                        .orderBy(Dbkeys.joinedOn,
                                            descending: true)
                                        .limit(Numberlimits
                                            .totalDatatoLoadAtOnceFromFirestore),
                                    true);
                                await FirebaseFirestore.instance
                                    .collection(DbPaths.collectionagents)
                                    .doc(agent!.id)
                                    .get()
                                    .then((doc) {
                                  agent = AgentModel.fromSnapshot(doc);
                                  setState(() {});
                                });
                                ShowLoading()
                                    .close(key: _keyLoader, context: context);
                                Utils.toast(getTranslatedForCurrentUser(
                                        context, 'xxxxxremovedsuccessxxx')
                                    .replaceAll('(####)',
                                        '${getTranslatedForCurrentUser(context, 'xxxphonenumberxx')}'));
                              },
                              styledDesc:
                                  '${getTranslatedForCurrentUser(context, 'xxagentxx')} <bold>${agent!.nickname}</bold> ${getTranslatedForCurrentUser(context, 'xxphoneremovedxxx')}',
                              plainDesc:
                                  '${getTranslatedForCurrentUser(context, 'xxagentxx')} ${agent!.nickname} ${getTranslatedForCurrentUser(context, 'xxphoneremovedxxx')} ',
                            );
                          }).catchError((e) {
                            ShowLoading()
                                .close(key: _keyLoader, context: context);
                            Utils.toast(
                                "${getTranslatedForCurrentUser(context, 'xxfailedxx')} $e");
                          });
                        },
                  child: MtCustomfontBoldSemi(
                    text: getTranslatedForCurrentUser(
                            context, 'xxxremovexxxxxx')
                        .replaceAll('(####)',
                            '${getTranslatedForCurrentUser(context, 'xxxphonenumberxx')}'),
                    color: Mycolors.red,
                    fontsize: 15,
                  ),
                ),
              ),
        onpressed: AppConstants.isdemomode == true
            ? () {
                Utils.toast(getTranslatedForCurrentUser(
                    context, 'xxxnotalwddemoxxaccountxx'));
              }
            : () async {
                if (_pcode.text.trim().length < 1 ||
                    (_pcode.text.trim().contains("+") &&
                        _pcode.text.trim().length < 2)) {
                  Utils.toast(
                      getTranslatedForCurrentUser(context, 'xxvalidccxx'));
                } else if (_pnumber.text.trim().length < 5) {
                  Utils.toast(getTranslatedForCurrentUser(
                      context, 'xxentervalidmobxx'));
                } else {
                  if (phone ==
                      "+${_pcode.text.trim()}${_pnumber.text.trim()}") {
                    Utils.toast(getTranslatedForCurrentUser(
                        context, 'xxxalreadyexistsxxx'));
                  } else {
                    String userid = agent!.id;
                    Navigator.of(context).pop();
                    ShowLoading().open(context: context, key: _keyLoader);

                    await FirebaseFirestore.instance
                        .collection(DbPaths.collectioncustomers)
                        .where(Dbkeys.phone,
                            isEqualTo:
                                "+" + _pcode.text.trim() + _pnumber.text.trim())
                        .get()
                        .then((customer) async {
                      if (customer.docs.length != 0) {
                        ShowLoading().close(key: _keyLoader, context: context);
                        Utils.toast(
                          getTranslatedForCurrentUser(
                                  context, 'xxusingphonexxx')
                              .replaceAll('(####)',
                                  '${getTranslatedForCurrentUser(context, 'xxcustomerxx')} ${customer.docs[0][Dbkeys.nickname]}'),
                        );
                      } else {
                        await FirebaseFirestore.instance
                            .collection(DbPaths.collectionagents)
                            .where(Dbkeys.phone,
                                isEqualTo: "+" +
                                    _pcode.text.trim() +
                                    _pnumber.text.trim())
                            .get()
                            .then((doc) async {
                          if (doc.docs.length == 0) {
                            await FirebaseFirestore.instance
                                .collection(DbPaths.collectionagents)
                                .doc(userid)
                                .update({
                              Dbkeys.phoneRaw: _pnumber.text.trim(),
                              Dbkeys.phone: "+" +
                                  _pcode.text.trim() +
                                  _pnumber.text.trim(),
                              Dbkeys.countryCode: "+" + _pcode.text.trim(),
                            }).then((value) async {
                              await Utils.sendDirectNotification(
                                  title: getTranslatedForCurrentUser(
                                      context, 'xxphoneupdatedxxx'),
                                  parentID: "AGENT--$userid",
                                  plaindesc:
                                      "${getTranslatedForCurrentUser(context, 'xxxphoneupdatedbyadminxx').replaceAll('(####)', '+${_pcode.text.trim() + _pnumber.text.trim()}')}",
                                  docRef: FirebaseFirestore.instance
                                      .collection(DbPaths.collectionagents)
                                      .doc(userid)
                                      .collection(DbPaths.agentnotifications)
                                      .doc(DbPaths.agentnotifications),
                                  postedbyID: 'Admin');
                              await FirebaseApi.runTransactionRecordActivity(
                                parentid: "AGENT--$userid",
                                title:
                                    "${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxphoneupdatedxxx')}",
                                postedbyID: "sys",
                                onErrorFn: (e) {
                                  ShowLoading()
                                      .close(key: _keyLoader, context: context);
                                  Utils.toast(
                                      "${getTranslatedForCurrentUser(context, 'xxfailedxx')} $e");
                                },
                                onSuccessFn: () {},
                                styledDesc:
                                    '${getTranslatedForCurrentUser(context, 'xxagentxx')} <bold> ${agent!.nickname}</bold> ${getTranslatedForCurrentUser(context, 'xxxphoneupdatedbyadminxx').replaceAll('(####)', "<bold>+${_pcode.text.trim() + _pnumber.text.trim()}</bold>")}',
                                plainDesc:
                                    '${getTranslatedForCurrentUser(context, 'xxagentxx')} ${agent!.nickname} ${getTranslatedForCurrentUser(context, 'xxxphoneupdatedbyadminxx').replaceAll('(####)', '+${_pcode.text.trim() + _pnumber.text.trim()}')}',
                              );
                            }).then((value) async {
                              final firestore =
                                  Provider.of<FirestoreDataProviderAGENTS>(
                                      context,
                                      listen: false);
                              firestore.fetchNextData(
                                  Dbkeys.dataTypeAGENTS,
                                  colRef
                                      .orderBy(Dbkeys.joinedOn,
                                          descending: true)
                                      .limit(Numberlimits
                                          .totalDatatoLoadAtOnceFromFirestore),
                                  true);
                              await FirebaseFirestore.instance
                                  .collection(DbPaths.collectionagents)
                                  .doc(userid)
                                  .get()
                                  .then((doc) {
                                agent = AgentModel.fromSnapshot(doc);
                                setState(() {});
                              });

                              ShowLoading()
                                  .close(key: _keyLoader, context: context);

                              Utils.toast(getTranslatedForCurrentUser(
                                  context, 'xxphoneupdatedxxx'));
                            }).catchError((e) {
                              ShowLoading()
                                  .close(key: _keyLoader, context: context);
                              Utils.toast(
                                  "${getTranslatedForCurrentUser(context, 'xxfailedxx')} $e");
                            });
                          } else {
                            ShowLoading()
                                .close(key: _keyLoader, context: context);
                            Utils.toast(
                              getTranslatedForCurrentUser(
                                      context, 'xxusingphonexxx')
                                  .replaceAll('(####)',
                                      '${getTranslatedForCurrentUser(context, 'xxagentxx')} ${customer.docs[0][Dbkeys.nickname]}'),
                            );
                          }
                        });
                      }
                    });
                  }
                }
              });
  }

  updateName(String name) {
    ShowFormDialog().open(
        controller: _name,
        hinttext:
            "${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxfullnamexx')}",
        context: context,
        title: getTranslatedForCurrentUser(context, 'xxupdatenamexxx'),
        subtitle: getTranslatedForCurrentUser(context, 'xxupdatenamexx'),
        buttontext: getTranslatedForCurrentUser(context, 'xxupdatexx'),
        onpressed: AppConstants.isdemomode == true
            ? () {
                Utils.toast(getTranslatedForCurrentUser(
                    context, 'xxxnotalwddemoxxaccountxx'));
              }
            : () async {
                if (_name.text.trim().length < 2) {
                  Utils.toast(getTranslatedForCurrentUser(
                      context, 'xxenterfullnamexx'));
                } else if (name == _name.text.trim()) {
                  Utils.toast(getTranslatedForCurrentUser(
                      context, 'xxxalreadyexistsxxx'));
                } else {
                  Navigator.of(context).pop();
                  ShowLoading().open(context: context, key: _keyLoader);
                  await colRef.doc(agent!.id).update({
                    Dbkeys.nickname: _name.text.trim(),
                    Dbkeys.searchKey:
                        _name.text.trim().substring(0, 1).toUpperCase(),
                  }).then((value) async {
                    var names = _name.text.trim().trim().split(' ');

                    String shortname = _name.text.trim().trim();
                    String lastName = "";
                    if (names.length > 1) {
                      shortname = names[0];
                      lastName = names[1];
                      if (shortname.length < 3) {
                        shortname = lastName;
                        if (lastName.length < 3) {
                          shortname = _name.text.trim();
                        }
                      }
                    }
                    await FirebaseApi.runUPDATEmapobjectinListField(
                        docrefdata: FirebaseFirestore.instance
                            .collection(DbPaths.userapp)
                            .doc(DbPaths.registry),
                        compareKey: Dbkeys.rgstUSERID,
                        compareVal: agent!.id,
                        onErrorFn: (err) {
                          ShowLoading()
                              .close(context: context, key: _keyLoader);

                          Utils.toast(getTranslatedForCurrentUser(
                                  context, 'xxfailedxx') +
                              err.toString());
                        },
                        replaceableMapObjectWithOnlyFieldsRequired: {
                          Dbkeys.rgstUSERID: agent!.id,
                          Dbkeys.rgstFULLNAME: _name.text.trim(),
                          Dbkeys.rgstSHORTNAME: shortname,
                        },
                        onSuccessFn: () async {
                          await Utils.sendDirectNotification(
                              title: getTranslatedForCurrentUser(
                                  context, 'xxnameupdatedxxx'),
                              parentID: "AGENT--${agent!.id}",
                              plaindesc: getTranslatedForCurrentUser(
                                      context, 'xxxacnameupdatedbyadminxx')
                                  .replaceAll(
                                      '(####)', '${_name.text.toString()}'),
                              docRef: FirebaseFirestore.instance
                                  .collection(DbPaths.collectionagents)
                                  .doc(agent!.id)
                                  .collection(DbPaths.agentnotifications)
                                  .doc(DbPaths.agentnotifications),
                              postedbyID: 'Admin');
                          await FirebaseApi.runTransactionRecordActivity(
                            parentid: "AGENT--${agent!.id}",
                            title:
                                "${getTranslatedForCurrentUser(context, 'xxagentxx')}${getTranslatedForCurrentUser(context, 'xxnameupdatedxxx')}",
                            postedbyID: "sys",
                            onErrorFn: (e) {
                              ShowLoading()
                                  .close(key: _keyLoader, context: context);
                              Utils.toast(
                                  "${getTranslatedForCurrentUser(context, 'xxfailedxx')}" +
                                      "$e");
                            },
                            onSuccessFn: () {},
                            styledDesc:
                                '${getTranslatedForCurrentUser(context, 'xxagentxx')} <bold> ${getTranslatedForCurrentUser(context, 'xxidxx')} ${agent!.id} </bold>${getTranslatedForCurrentUser(context, 'xxxacnameupdatedbyadminxx').replaceAll('(####)', '${_name.text.toString()}')}.',
                            plainDesc:
                                '${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxidxx')} ${agent!.id} ${getTranslatedForCurrentUser(context, 'xxxacnameupdatedbyadminxx').replaceAll('(####)', '${_name.text.toString()}')}.',
                          );

                          final firestore =
                              Provider.of<FirestoreDataProviderAGENTS>(context,
                                  listen: false);
                          firestore.fetchNextData(
                              Dbkeys.dataTypeAGENTS,
                              colRef
                                  .orderBy(Dbkeys.joinedOn, descending: true)
                                  .limit(Numberlimits
                                      .totalDatatoLoadAtOnceFromFirestore),
                              true);

                          await FirebaseFirestore.instance
                              .collection(DbPaths.collectionagents)
                              .doc(agent!.id)
                              .get()
                              .then((doc) {
                            agent = AgentModel.fromSnapshot(doc);
                            setState(() {});
                          });
                          ShowLoading()
                              .close(key: _keyLoader, context: context);
                          Utils.toast(
                              "${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxxnameupdatedsuccesxxx')}");
                        }).catchError((e) {
                      ShowLoading().close(context: context, key: _keyLoader);

                      Utils.toast(
                          "${getTranslatedForCurrentUser(context, 'xxfailedxx')}" +
                              e.toString());
                    });
                  }).catchError((e) {
                    ShowLoading().close(context: context, key: _keyLoader);

                    Utils.toast(
                        "${getTranslatedForCurrentUser(context, 'xxfailedxx')}" +
                            e.toString());
                  });
                }
              });
  }

  Future uploadSelectedLocalFileWithProgressIndicator(
      File selectedFile, bool isVideo, bool isthumbnail, int timeEpoch,
      {String? filenameoptional}) async {
    String ext = p.extension(selectedFile.path);
    String fileName = agent!.id + ext;
    // isthumbnail == false
    //     ? isVideo == true
    //         ? 'Video-$timeEpoch.mp4'
    //         : '$timeEpoch'
    //     : '${timeEpoch}Thumbnail.png'
    // );
    Reference reference =
        FirebaseStorage.instance.ref("AgentProfilePics/").child(fileName);

    UploadTask uploading = reference.putFile(selectedFile);

    showDialog<void>(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new WillPopScope(
              onWillPop: () async => false,
              child: SimpleDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  // side: BorderSide(width: 5, color: Colors.green)),
                  key: _keyLoader,
                  backgroundColor: Colors.white,
                  children: <Widget>[
                    Center(
                      child: StreamBuilder(
                          stream: uploading.snapshotEvents,
                          builder: (BuildContext context, snapshot) {
                            if (snapshot.hasData) {
                              final TaskSnapshot snap = uploading.snapshot;

                              return openUploadDialog(
                                context: context,
                                percent: bytesTransferred(snap) / 100,
                                title: isthumbnail == true
                                    ? getTranslatedForCurrentUser(
                                        context, 'xxgeneratingthumbnailxx')
                                    : getTranslatedForCurrentUser(
                                        context, 'xxsendingxx'),
                                subtitle:
                                    "${((((snap.bytesTransferred / 1024) / 1000) * 100).roundToDouble()) / 100}/${((((snap.totalBytes / 1024) / 1000) * 100).roundToDouble()) / 100} MB",
                              );
                            } else {
                              return openUploadDialog(
                                context: context,
                                percent: 0.0,
                                title: isthumbnail == true
                                    ? getTranslatedForCurrentUser(
                                        context, 'xxgeneratingthumbnailxx')
                                    : getTranslatedForCurrentUser(
                                        context, 'xxsendingxx'),
                                subtitle: '',
                              );
                            }
                          }),
                    ),
                  ]));
        });

    TaskSnapshot downloadTask = await uploading;
    String downloadedurl = await downloadTask.ref.getDownloadURL();

    // if (isthumbnail == true) {
    //   MediaInfo _mediaInfo = MediaInfo();

    //   await _mediaInfo.getMediaInfo(selectedFile.path).then((mediaInfo) {
    //     setStateIfMounted(() {
    //       videometadata = jsonEncode({
    //         "width": mediaInfo['width'],
    //         "height": mediaInfo['height'],
    //         "orientation": null,
    //         "duration": mediaInfo['durationMs'],
    //         "filesize": null,
    //         "author": null,
    //         "date": null,
    //         "framerate": null,
    //         "location": null,
    //         "path": null,
    //         "title": '',
    //         "mimetype": mediaInfo['mimeType'],
    //       }).toString();
    //     });
    //   }).catchError((onError) {
    //     Utils.toast('Sending failed !');
    //     print('ERROR SENDING FILE: $onError');
    //   });
    // } else {
    //   FirebaseFirestore.instance
    //       .collection(DbPaths.collectionagents)
    //       .doc(widget.currentUserID)
    //       .set({
    //     Dbkeys.mssgSent: FieldValue.increment(1),
    //   }, SetOptions(merge: true));
    //   FirebaseFirestore.instance
    //       .collection(DbPaths.userapp)
    //       .doc(DbPaths.docdashboarddata)
    //       .set({
    //     Dbkeys.mediamessagessent: FieldValue.increment(1),
    //   }, SetOptions(merge: true));
    // }
    Navigator.of(_keyLoader.currentContext!, rootNavigator: true).pop(); //
    return downloadedurl;
  }

  Widget ratingbar({double? rate}) {
    return RatingBarIndicator(
      rating: rate ?? 1.15,
      itemBuilder: (context, index) => Icon(
        Icons.star,
        color: Colors.amber,
      ),
      itemCount: 5,
      itemSize: 15.0,
      direction: Axis.horizontal,
    );
  }

  setAsOffline(
    BuildContext context,
  ) async {
    final firestore =
        Provider.of<FirestoreDataProviderAGENTS>(context, listen: false);
    Utils.toast(getTranslatedForCurrentUser(context, 'xxplswaitxx'));
    await colRef.doc(agent!.id).update({
      Dbkeys.lastSeen: DateTime.now().millisecondsSinceEpoch,
    });

    await firestore.updateparticulardocinProvider(
        userid: agent!.id,
        colRef: colRef,
        onfetchDone: (userDoc) {
          setState(() {
            agent = AgentModel.fromSnapshot(userDoc);
          });
        });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _name.dispose();
    _email.dispose();
    _pcode.dispose();
    _pnumber.dispose();
  }

  Widget buildheader() {
    final observer = Provider.of<Observer>(context, listen: false);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(12, 12, 12.0, 7.0),
                  padding: EdgeInsets.only(bottom: 10),
                  width: 85,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Mycolors.greylightcolor,
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: agent!.accountstatus == Dbkeys.sTATUSblocked
                          ? NetworkImage(
                              AppConstants.defaultprofilepicfromnetworklink)
                          : NetworkImage(agent!.photoUrl == ''
                              ? AppConstants.defaultprofilepicfromnetworklink
                              : agent!.photoUrl),
                    ),
                  ),
                ),
                agent!.lastSeen == true
                    ? Positioned(
                        bottom: 10,
                        child: Container(
                            padding: EdgeInsets.fromLTRB(6, 3, 6, 3),
                            decoration:
                                boxDecoration(radius: 10, showShadow: false),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 3),
                                MtCustomfontMedium(
                                  text: getTranslatedForCurrentUser(
                                      context, 'xxonlinexx'),
                                  fontsize: 12,
                                )
                              ],
                            )))
                    : SizedBox(),
                Positioned(
                    top: 10,
                    right: 15,
                    child: CircleAvatar(
                        backgroundColor: Mycolors.secondary,
                        radius: 17,
                        child: IconButton(
                            onPressed: AppConstants.isdemomode == true
                                ? () {
                                    Utils.toast(getTranslatedForCurrentUser(
                                        context, 'xxxnotalwddemoxxaccountxx'));
                                  }
                                : () async {
                                    final firestore = Provider.of<
                                            FirestoreDataProviderAGENTS>(
                                        context,
                                        listen: false);
                                    await Navigator.push(
                                        context,
                                        new MaterialPageRoute(
                                            builder: (context) =>
                                                new CameraImageGalleryPicker(
                                                  onTakeFile: (file) async {
                                                    setStatusBarColor();

                                                    int timeStamp = DateTime
                                                            .now()
                                                        .millisecondsSinceEpoch;

                                                    String? url =
                                                        await uploadSelectedLocalFileWithProgressIndicator(
                                                            file,
                                                            false,
                                                            false,
                                                            timeStamp);
                                                    if (url != null) {
                                                      ShowLoading().open(
                                                          context: this.context,
                                                          key: _keyLoader2);
                                                      await colRef
                                                          .doc(agent!.id)
                                                          .update({
                                                        Dbkeys.photoUrl: url,
                                                      }).then((value) async {
                                                        await FirebaseApi
                                                            .runUPDATEmapobjectinListField(
                                                                docrefdata: FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        DbPaths
                                                                            .userapp)
                                                                    .doc(DbPaths
                                                                        .registry),
                                                                compareKey: Dbkeys
                                                                    .rgstUSERID,
                                                                compareVal:
                                                                    agent!.id,
                                                                onErrorFn:
                                                                    (err) {
                                                                  ShowLoading().close(
                                                                      context: this
                                                                          .context,
                                                                      key:
                                                                          _keyLoader2);

                                                                  Utils.toast(
                                                                      "${getTranslatedForCurrentUser(context, 'xxfailedxx')} " +
                                                                          err.toString());
                                                                },
                                                                replaceableMapObjectWithOnlyFieldsRequired: {
                                                                  Dbkeys.rgstUSERID:
                                                                      agent!.id,
                                                                  Dbkeys.rgstPHOTOURL:
                                                                      url,
                                                                },
                                                                onSuccessFn:
                                                                    () async {
                                                                  await Utils.sendDirectNotification(
                                                                      title: getTranslatedForCurrentUser(
                                                                          context,
                                                                          'xxxphotoupdatedxxx'),
                                                                      parentID:
                                                                          "AGENT--${agent!.id}",
                                                                      plaindesc: getTranslatedForCurrentUser(
                                                                          context,
                                                                          'xxxyouracphotoxxx'),
                                                                      docRef: FirebaseFirestore
                                                                          .instance
                                                                          .collection(DbPaths
                                                                              .collectionagents)
                                                                          .doc(agent!
                                                                              .id)
                                                                          .collection(DbPaths
                                                                              .agentnotifications)
                                                                          .doc(DbPaths
                                                                              .agentnotifications),
                                                                      postedbyID:
                                                                          'Admin');
                                                                  await FirebaseApi
                                                                      .runTransactionRecordActivity(
                                                                          parentid:
                                                                              "AGENT--${agent!.id}",
                                                                          title:
                                                                              "${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxxphotoupdatedxxx')}",
                                                                          postedbyID:
                                                                              "sys",
                                                                          onErrorFn:
                                                                              (e) {
                                                                            ShowLoading().close(
                                                                                key: _keyLoader2,
                                                                                context: this.context);
                                                                            Utils.toast("${getTranslatedForCurrentUser(context, 'xxfailedxx')} $e");
                                                                          },
                                                                          onSuccessFn:
                                                                              () {},
                                                                          styledDesc:
                                                                              '${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxidxx')} <bold>${agent!.id}</bold> ${getTranslatedForCurrentUser(context, 'xxxphotoupdatedxxx')} ${getTranslatedForCurrentUser(context, 'xxxbyxxx')} ${getTranslatedForCurrentUser(context, 'xxadminxx')}',
                                                                          plainDesc:
                                                                              '${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxidxx')} ${agent!.id} ${getTranslatedForCurrentUser(context, 'xxxphotoupdatedxxx')} ${getTranslatedForCurrentUser(context, 'xxxbyxxx')} ${getTranslatedForCurrentUser(context, 'xxadminxx')}');

                                                                  firestore.fetchNextData(
                                                                      Dbkeys
                                                                          .dataTypeAGENTS,
                                                                      colRef
                                                                          .orderBy(
                                                                              Dbkeys.joinedOn,
                                                                              descending: true)
                                                                          .limit(Numberlimits.totalDatatoLoadAtOnceFromFirestore),
                                                                      true);

                                                                  await FirebaseFirestore
                                                                      .instance
                                                                      .collection(
                                                                          DbPaths
                                                                              .collectionagents)
                                                                      .doc(agent!
                                                                          .id)
                                                                      .get()
                                                                      .then(
                                                                          (doc) {
                                                                    agent = AgentModel
                                                                        .fromSnapshot(
                                                                            doc);
                                                                    setState(
                                                                        () {});
                                                                  });
                                                                  ShowLoading().close(
                                                                      key:
                                                                          _keyLoader2,
                                                                      context: this
                                                                          .context);
                                                                  Utils.toast(
                                                                      "${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxxphotoupdatedxxx')}");
                                                                }).catchError(
                                                            (e) {
                                                          ShowLoading().close(
                                                              context:
                                                                  this.context,
                                                              key: _keyLoader2);

                                                          Utils.toast(
                                                              "${getTranslatedForCurrentUser(context, 'xxfailedxx')} " +
                                                                  e.toString());
                                                        });
                                                      });
                                                      await file.delete();
                                                    }
                                                  },
                                                )));
                                  },
                            icon: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 15,
                            ))))
              ],
            ),
          ],
        ),
        Container(
          width: MediaQuery.of(context).size.width / 1.6,
          padding: EdgeInsets.fromLTRB(10.0, 25.0, 0.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  MtCustomfontBold(
                    color: Mycolors.white,
                    text: agent!.nickname,
                    fontsize: 19.5,
                  ),
                  SizedBox(width: 10),
                  CircleAvatar(
                      backgroundColor: Mycolors.secondary,
                      radius: 12,
                      child: IconButton(
                          onPressed: AppConstants.isdemomode == true
                              ? () {
                                  Utils.toast(getTranslatedForCurrentUser(
                                      context, 'xxxnotalwddemoxxaccountxx'));
                                }
                              : () async {
                                  await updateName(agent!.nickname);
                                },
                          icon: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 10,
                          )))
                ],
              ),

              Divider(
                color: Colors.white10,
              ),

              SizedBox(
                height: 5.0,
              ),

              // Row(
              //   crossAxisAlignment: CrossAxisAlignment.end,
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   children: [
              //     Icon(Icons.timer, color: Colors.white, size: 15),
              //     SizedBox(width: 10),
              //     MtCustomfontRegular(
              //       text: 'Lastseen 12 years ago ',
              //       color: Mycolors.whitelight,
              //       fontsize: 13,
              //     ),
              //   ],
              // ),
              SizedBox(
                height: 8.0,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.account_box, color: Colors.white, size: 15),
                  SizedBox(width: 10),
                  MtCustomfontRegular(
                    text:
                        '${getTranslatedForCurrentUser(context, 'xxidxx')} ${agent!.id}',
                    color: Mycolors.whitelight,
                    fontsize: 13,
                  ),
                ],
              ),
              SizedBox(
                height: 11.0,
              ),
              observer.basicSettingUserApp!.loginTypeUserApp == "Email/Password"
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.email, color: Colors.white, size: 15),
                        SizedBox(width: 10),
                        MtCustomfontRegular(
                          text: agent!.email == ""
                              ? ""
                              : AppConstants.isdemomode == true
                                  ? '*${agent!.email.substring(1, 4)}********'
                                  : '${agent!.email}',
                          color: Mycolors.whitelight,
                          fontsize: 13,
                        ),
                        SizedBox(width: 20),
                        CircleAvatar(
                            backgroundColor: Mycolors.secondary,
                            radius: 12,
                            child: IconButton(
                                onPressed: AppConstants.isdemomode == true
                                    ? () {
                                        Utils.toast(getTranslatedForCurrentUser(
                                            context,
                                            'xxxnotalwddemoxxaccountxx'));
                                      }
                                    : () async {
                                        await updateEmail(agent!.phone);
                                      },
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 10,
                                )))
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.phone, color: Colors.white, size: 15),
                        SizedBox(width: 10),
                        MtCustomfontRegular(
                          text: agent!.phone == ""
                              ? ""
                              : AppConstants.isdemomode == true
                                  ? '${agent!.phone.substring(0, 6)}********'
                                  : '${agent!.phone}',
                          color: Mycolors.whitelight,
                          fontsize: 13,
                        ),
                        SizedBox(width: 20),
                        CircleAvatar(
                            backgroundColor: Mycolors.secondary,
                            radius: 12,
                            child: IconButton(
                                onPressed: AppConstants.isdemomode == true
                                    ? () {
                                        Utils.toast(getTranslatedForCurrentUser(
                                            context,
                                            'xxxnotalwddemoxxaccountxx'));
                                      }
                                    : () async {
                                        await updateMobile(agent!.phone);
                                      },
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 10,
                                )))
                      ],
                    ),
              SizedBox(
                height: 11.0,
              ),

              SizedBox(
                height: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  final GlobalKey<State> _keyLoader = new GlobalKey<State>(debugLabel: '0000');
  final GlobalKey<State> _keyLoader2 =
      new GlobalKey<State>(debugLabel: '00002');
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return NetworkSensitive(
      child: Utils.getNTPWrappedWidget(Consumer<Observer>(
          builder: (context, observer, _child) => Consumer<CommonSession>(
              builder: (context, user, _child) => agent == null
                  ? Scaffold(
                      backgroundColor: Mycolors.backgroundcolor,
                      body: circularProgress(),
                    )
                  : MyScaffold(
                      iconTextColor: Mycolors.white,
                      appbarColor: Mycolors.primary,
                      elevation: 0,
                      icondata1: Icons.notifications,
                      icon1press: () {
                        pageNavigator(
                            context,
                            UsersNotifiaction(
                                docRef: FirebaseFirestore.instance
                                    .collection(DbPaths.collectionagents)
                                    .doc(agent!.id)
                                    .collection(DbPaths.agentnotifications)
                                    .doc(DbPaths.agentnotifications)));
                      },
                      // icondata1: agent.email == '' ? null : Icons.email_outlined,
                      icondata2:
                          observer.basicSettingUserApp!.loginTypeUserApp ==
                                  "Email/Password"
                              ? agent!.email == ""
                                  ? null
                                  : Icons.email
                              : agent!.phone == ''
                                  ? null
                                  : Icons.call,
                      icon2press: AppConstants.isdemomode == true
                          ? () {
                              Utils.toast(getTranslatedForCurrentUser(
                                  context, 'xxxnotalwddemoxxaccountxx'));
                            }
                          : () {
                              if (observer
                                      .basicSettingUserApp!.loginTypeUserApp ==
                                  "Email/Password") {
                                final Uri params = Uri(
                                  scheme: 'mailto',
                                  path: agent!.email,
                                );

                                launchUrl(params,
                                    mode: LaunchMode.platformDefault);
                              } else {
                                final Uri params = Uri(
                                  scheme: 'tel',
                                  path: agent!.phone,
                                );
                                launchUrl(params,
                                    mode: LaunchMode.platformDefault);
                              }
                            },
                      scaffoldkey: _scaffoldKey,
                      title:
                          '${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxprofilexxx')}',
                      // appBar: AppBar(
                      //   elevation: 0,
                      //   titleSpacing: 0,
                      //   title: MtCustomfontBold(
                      //     color: Mycolors.white,
                      //     text: 'Profile',
                      //   ),
                      //   backgroundColor: Mycolors.primary,
                      // ),
                      body: ListView(
                        children: [
                          Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Column(children: [
                                Container(
                                  height: 240,
                                  color: Mycolors.primary,
                                  child: Row(children: [buildheader()]),
                                ),
                                Container(
                                  height: 110,
                                  color: Colors.transparent,
                                ),
                              ]),
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  alignment: Alignment.center,
                                  margin: EdgeInsets.all(5),
                                  padding: EdgeInsets.all(2),
                                  child: GridView(
                                    physics: NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          pageNavigator(
                                              context,
                                              AllDepartmentList(
                                                  filteragentid: agent!.id,
                                                  isShowForSignleAgent: true,
                                                  currentuserid:
                                                      Optionalconstants
                                                          .currentAdminID,
                                                  onbackpressed: () {
                                                    fetchUserAppSettings();
                                                  }));
                                        },
                                        child: eachGridTile(
                                            label: getTranslatedForCurrentUser(
                                                context, 'xxdepartmentsxx'),
                                            width: w / 1.0,
                                            icon: MtPoppinsBold(
                                              lineheight: 0.8,
                                              text: userAppSettings == null
                                                  ? "0"
                                                  : userAppSettings!
                                                              .departmentBasedContent ==
                                                          false
                                                      ? "--"
                                                      : myDepartmentList.length
                                                          .toString(),
                                              color: Mycolors.grey,
                                              fontsize: 22,
                                            )),
                                      ),
                                      myinkwell(
                                        onTap: () {
                                          pageNavigator(
                                              context,
                                              AllTickets(
                                                  subtitle:
                                                      "${getTranslatedForCurrentUser(context, 'xxagentxx')} : ${agent!.nickname}  (${getTranslatedForCurrentUser(context, 'xxidxx')} ${agent!.id})",
                                                  userAppSettingsModel:
                                                      userAppSettings!,
                                                  query: FirebaseFirestore
                                                      .instance
                                                      .collection(DbPaths
                                                          .collectiontickets)
                                                      .where(
                                                          Dbkeys
                                                              .tktMEMBERSactiveList,
                                                          arrayContainsAny: [
                                                        agent!.id
                                                      ])));
                                        },
                                        child: eachGridTile(
                                            label: getTranslatedForCurrentUser(
                                                context, 'xxtktssxx'),
                                            width: w / 1.0,
                                            icon:
                                                // userAppSettings == null ||
                                                //         myDepartmentList.length == 0
                                                //     ? MtPoppinsBold(
                                                //         lineheight: 0.8,
                                                //         text: '0',
                                                //         color: Mycolors.grey,
                                                //         fontsize: 22,
                                                //       )
                                                //     :
                                                futureLoadCollections(
                                                    future:
                                                        //  userAppSettings!
                                                        //         .departmentBasedContent!
                                                        //     ? FirebaseFirestore
                                                        //         .instance
                                                        //         .collection(DbPaths
                                                        //             .collectiontickets)
                                                        //         .where(
                                                        //             Dbkeys
                                                        //                 .departmentNamestoredinList,
                                                        //             arrayContainsAny:
                                                        //                 myDepartmentList)
                                                        //         .get()
                                                        //     :
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(DbPaths
                                                                .collectiontickets)
                                                            .where(
                                                                Dbkeys
                                                                    .tktMEMBERSactiveList,
                                                                arrayContainsAny: [
                                                          agent!.id
                                                        ]).get(),
                                                    placeholder: MtPoppinsBold(
                                                      lineheight: 0.8,
                                                      text: '0',
                                                      color: Mycolors.grey,
                                                      fontsize: 22,
                                                    ),
                                                    noDataWidget: MtPoppinsBold(
                                                      lineheight: 0.8,
                                                      text: '0',
                                                      color: Mycolors.grey,
                                                      fontsize: 22,
                                                    ),
                                                    onfetchdone: (docs) {
                                                      return MtPoppinsBold(
                                                        lineheight: 0.8,
                                                        text: '${docs.length}',
                                                        color: Mycolors.grey,
                                                        fontsize: 22,
                                                      );
                                                    })),
                                      ),
                                      myinkwell(
                                        onTap: () {
                                          pageNavigator(
                                              context,
                                              AllGroups(
                                                subtitle:
                                                    "${getTranslatedForCurrentUser(context, 'xxagentxx')} : ${agent!.nickname}  (${getTranslatedForCurrentUser(context, 'xxidxx')} ${agent!.id})",
                                                query: FirebaseFirestore
                                                    .instance
                                                    .collection(DbPaths
                                                        .collectionAgentGroups)
                                                    .where(
                                                        Dbkeys.groupMEMBERSLIST,
                                                        arrayContainsAny: [
                                                      agent!.id
                                                    ]),
                                              ));
                                        },
                                        child: eachGridTile(
                                            label: getTranslatedForCurrentUser(
                                                context, 'xxxgroupsxxx'),
                                            width: w / 1.0,
                                            icon: futureLoadCollections(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .collection(DbPaths
                                                        .collectionAgentGroups)
                                                    .where(
                                                        Dbkeys.groupMEMBERSLIST,
                                                        arrayContainsAny: [
                                                      agent!.id
                                                    ]).get(),
                                                placeholder: MtPoppinsBold(
                                                  lineheight: 0.8,
                                                  text: '0',
                                                  color: Mycolors.grey,
                                                  fontsize: 22,
                                                ),
                                                noDataWidget: MtPoppinsBold(
                                                  lineheight: 0.8,
                                                  text: '0',
                                                  color: Mycolors.grey,
                                                  fontsize: 22,
                                                ),
                                                onfetchdone: (docs) {
                                                  return MtPoppinsBold(
                                                    lineheight: 0.8,
                                                    text: '${docs.length}',
                                                    color: Mycolors.grey,
                                                    fontsize: 22,
                                                  );
                                                })),
                                      ),
                                      myinkwell(
                                        onTap: () {
                                          pageNavigator(
                                              context,
                                              AllAgentsChat(
                                                subtitle:
                                                    "${getTranslatedForCurrentUser(context, 'xxagentxx')} : ${agent!.nickname}  (${getTranslatedForCurrentUser(context, 'xxidxx')} ${agent!.id})",
                                                query: FirebaseFirestore
                                                    .instance
                                                    .collection(DbPaths
                                                        .collectionAgentIndividiualmessages)
                                                    .where("chatmembers",
                                                        arrayContainsAny: [
                                                      agent!.id
                                                    ]),
                                              ));
                                        },
                                        child: eachGridTile(
                                            label:
                                                '${getTranslatedForCurrentUser(context, 'xxagentchatsxx')}',
                                            width: w / 1.0,
                                            icon: futureLoadCollections(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .collection(DbPaths
                                                        .collectionAgentIndividiualmessages)
                                                    .where("chatmembers",
                                                        arrayContainsAny: [
                                                      agent!.id
                                                    ]).get(),
                                                placeholder: MtPoppinsBold(
                                                  lineheight: 0.8,
                                                  text: '0',
                                                  color: Mycolors.grey,
                                                  fontsize: 22,
                                                ),
                                                noDataWidget: MtPoppinsBold(
                                                  lineheight: 0.8,
                                                  text: '0',
                                                  color: Mycolors.grey,
                                                  fontsize: 22,
                                                ),
                                                onfetchdone: (docs) {
                                                  return MtPoppinsBold(
                                                    lineheight: 0.8,
                                                    text: '${docs.length}',
                                                    color: Mycolors.grey,
                                                    fontsize: 22,
                                                  );
                                                })),
                                      ),
                                      eachGridTile(
                                          label: getTranslatedForCurrentUser(
                                              context, 'xxxandroidxxx'),
                                          width: w / 1.0,
                                          icon: MtPoppinsBold(
                                            lineheight: 0.8,
                                            text:
                                                '${agent!.totalvisitsANDROID}',
                                            color: Mycolors.grey,
                                            fontsize: 22,
                                          )),
                                      eachGridTile(
                                          label: getTranslatedForCurrentUser(
                                              context, 'xxxiosvisistsxxx'),
                                          width: w / 1.0,
                                          icon: MtPoppinsBold(
                                            lineheight: 0.8,
                                            text: '${agent!.totalvisitsIOS}',
                                            color: Mycolors.grey,
                                            fontsize: 22,
                                          )),
                                    ],
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            childAspectRatio: 1.35,
                                            mainAxisSpacing: 4,
                                            crossAxisSpacing: 4),
                                    padding: EdgeInsets.all(2),
                                  ),
                                  decoration: boxDecoration(showShadow: true),
                                  height: 170,
                                  width: w / 1.1,
                                ),
                                //  Container(
                                //   child: Column(
                                //     mainAxisAlignment:
                                //         MainAxisAlignment.spaceEvenly,
                                //     children: [
                                //       Row(
                                //           mainAxisAlignment:
                                //               MainAxisAlignment.spaceAround,
                                //           children: [
                                //             eachcount(
                                //                 text: 'Audio Call Made',
                                //                 count:
                                //                     '${userDoc[Dbkeys.audiocallsmade]}'),
                                //             myverticaldivider(
                                //                 height: 50,
                                //                 color: Mycolors.greylightcolor),
                                //             eachcount(text: 'Video Calls'),
                                //             myverticaldivider(
                                //                 height: 50,
                                //                 color: Mycolors.greylightcolor),
                                //             eachcount(text: 'Media Sent'),
                                //           ]),
                                //       myvhorizontaldivider(width: w / 1.2),
                                //       Row(
                                //           mainAxisAlignment:
                                //               MainAxisAlignment.spaceAround,
                                //           children: [
                                //             eachcount(
                                //                 text: 'Audio Calls',
                                //                 count:
                                //                     '${userDoc[Dbkeys.audiocallsmade]}'),
                                //             myverticaldivider(
                                //                 height: 50,
                                //                 color: Mycolors.greylightcolor),
                                //             eachcount(text: 'Video Calls'),
                                //             myverticaldivider(
                                //                 height: 50,
                                //                 color: Mycolors.greylightcolor),
                                //             eachcount(text: 'Media Sent'),
                                //           ]),
                                //     ],
                                //   ),

                                // )
                              ),
                            ],
                          ),
                          Padding(
                              padding: EdgeInsets.all(20),
                              child: observer.basicSettingUserApp == null
                                  ? SizedBox()
                                  : observer.basicSettingUserApp!
                                                  .loginTypeUserApp ==
                                              "Email/Password" &&
                                          agent!.email == ""
                                      ? Column(
                                          children: [
                                            MtCustomfontBold(
                                              lineheight: 1.2,
                                              textalign: TextAlign.center,
                                              text: getTranslatedForCurrentUser(
                                                  context,
                                                  'xxxnoemaillinkedxxx'),
                                              color: Mycolors.red,
                                              fontsize: 13,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(13.0),
                                              child: MySimpleButtonWithIcon(
                                                iconData: Icons.add,
                                                buttoncolor: Mycolors.orange,
                                                buttontext:
                                                    getTranslatedForCurrentUser(
                                                        context,
                                                        'xxxaddemailxxx'),
                                                onpressed:
                                                    AppConstants.isdemomode ==
                                                            true
                                                        ? () {
                                                            Utils.toast(
                                                                getTranslatedForCurrentUser(
                                                                    context,
                                                                    'xxxnotalwddemoxxaccountxx'));
                                                          }
                                                        : () async {
                                                            await updateEmail(
                                                                agent!.email);
                                                          },
                                              ),
                                            )
                                          ],
                                        )
                                      : observer.basicSettingUserApp!
                                                      .loginTypeUserApp ==
                                                  "Phone" &&
                                              agent!.phone == ""
                                          ? Column(
                                              children: [
                                                MtCustomfontBold(
                                                  lineheight: 1.2,
                                                  textalign: TextAlign.center,
                                                  text:
                                                      getTranslatedForCurrentUser(
                                                          context,
                                                          'xxxphonelinkedxxx'),
                                                  color: Mycolors.red,
                                                  fontsize: 13,
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      13.0),
                                                  child: MySimpleButtonWithIcon(
                                                    iconData: Icons.add,
                                                    buttoncolor:
                                                        Mycolors.orange,
                                                    buttontext:
                                                        getTranslatedForCurrentUser(
                                                            context,
                                                            'xxxaddphonexxx'),
                                                    onpressed: AppConstants
                                                                .isdemomode ==
                                                            true
                                                        ? () {
                                                            Utils.toast(
                                                                getTranslatedForCurrentUser(
                                                                    context,
                                                                    'xxxnotalwddemoxxaccountxx'));
                                                          }
                                                        : () async {
                                                            await updateMobile(
                                                                agent!.phone);
                                                          },
                                                  ),
                                                )
                                              ],
                                            )
                                          : SizedBox()),
                          InputSwitch(
                            onString: agent!.accountstatus ==
                                    Dbkeys.sTATUSallowed
                                ? ' ${getTranslatedForCurrentUser(context, 'xxstatusxx')}:  ${getTranslatedForCurrentUser(context, 'xxxapprovedxxx')}'
                                : agent!.accountstatus == Dbkeys.sTATUSblocked
                                    ? ' ${getTranslatedForCurrentUser(context, 'xxstatusxx')}:  ${getTranslatedForCurrentUser(context, 'xxxblockedxxx')}'
                                    : agent!.accountstatus ==
                                            Dbkeys.sTATUSallowed
                                        ? ' ${getTranslatedForCurrentUser(context, 'xxstatusxx')}:  ${getTranslatedForCurrentUser(context, 'xxxpendingapprovalxxx')}'
                                        : '',
                            offString: agent!.accountstatus ==
                                    Dbkeys.sTATUSallowed
                                ? ' ${getTranslatedForCurrentUser(context, 'xxstatusxx')}:  ${getTranslatedForCurrentUser(context, 'xxxapprovedxxx')}'
                                : agent!.accountstatus == Dbkeys.sTATUSblocked
                                    ? ' ${getTranslatedForCurrentUser(context, 'xxstatusxx')}:  ${getTranslatedForCurrentUser(context, 'xxxblockedxxx')}'
                                    : agent!.accountstatus ==
                                            Dbkeys.sTATUSallowed
                                        ? ' ${getTranslatedForCurrentUser(context, 'xxstatusxx')}:  ${getTranslatedForCurrentUser(context, 'xxxpendingapprovalxxx')}'
                                        : '${getTranslatedForCurrentUser(context, 'xxstatusxx')}',
                            initialbool: agent!.accountstatus ==
                                    Dbkeys.sTATUSallowed
                                ? true
                                : agent!.accountstatus == Dbkeys.sTATUSblocked
                                    ? false
                                    : agent!.accountstatus ==
                                            Dbkeys.sTATUSpending
                                        ? false
                                        : false,
                            onChanged: AppConstants.isdemomode == true
                                ? (val) {
                                    Utils.toast(getTranslatedForCurrentUser(
                                        context, 'xxxnotalwddemoxxaccountxx'));
                                  }
                                : (val) async {
                                    await confirmchangeswitch(
                                      context,
                                      agent!.accountstatus,
                                      agent!.id,
                                      agent!.nickname,
                                      agent!.photoUrl,
                                    );
                                  },
                          ),

                          agent!.accountstatus == Dbkeys.sTATUSblocked ||
                                  agent!.accountstatus == Dbkeys.sTATUSpending
                              ? Container(
                                  decoration: boxDecoration(
                                      radius: 7,
                                      color: Mycolors.orange,
                                      bgColor:
                                          Mycolors.orange.withOpacity(0.2)),
                                  width: w,
                                  margin: EdgeInsets.all(12),
                                  padding: EdgeInsets.fromLTRB(12, 15, 12, 15),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      MtCustomfontBoldSemi(
                                        textalign: TextAlign.left,
                                        text:
                                            '${getTranslatedForCurrentUser(context, 'xxxuseralertmessagexxx')} - ',
                                        fontsize: 14,
                                        color: Colors.orange[800],
                                      ),
                                      Divider(),
                                      MtCustomfontBoldSemi(
                                          textalign: TextAlign.left,
                                          text: agent!.actionmessage,
                                          fontsize: 14,
                                          color: Mycolors.black,
                                          lineheight: 1.3)
                                    ],
                                  ),
                                )
                              : SizedBox(),

                          // Container(
                          //   color: Colors.white,
                          //   child: ListTile(
                          //     title: MtCustomfontMedium(
                          //       fontsize: 16,
                          //       color: Mycolors.black,
                          //       text: 'Send Notification',
                          //     ),

                          //     subtitle: MtCustomfontRegular(
                          //       text: 'Send Notification to this User Only',
                          //       fontsize: 13,
                          //     ),
                          //     trailing: Icon(Icons.keyboard_arrow_right),
                          //     leading: Icon(
                          //       EvaIcons.paperPlane,
                          //       color: Mycolors.primary,
                          //     ),
                          //     // isThreeLine: true,
                          //     onTap: () async {
                          //       await createNotificationID(
                          //           context, RandomDigits.getString(8));
                          //     },
                          //   ),
                          // ),
                          SizedBox(
                            height: 10,
                          ),
                          // Container(
                          //   color: Colors.white,
                          //   child: ListTile(
                          //     title: MtCustomfontMedium(
                          //       fontsize: 16,
                          //       color: Mycolors.black,
                          //       text: 'Call History',
                          //     ),

                          //     subtitle: MtCustomfontRegular(
                          //       text: 'See User Call Log',
                          //       fontsize: 13,
                          //     ),
                          //     trailing: Icon(Icons.keyboard_arrow_right),
                          //     leading: Icon(
                          //       EvaIcons.phoneCallOutline,
                          //       color: Mycolors.primary,
                          //     ),
                          //     // isThreeLine: true,
                          //     onTap: () async {
                          //       // pageNavigator(
                          //       //     context,
                          //       //     CallHistory(
                          //       //       userphone: userDoc[Dbkeys.uSERphone],
                          //       //       fullname: userDoc[Dbkeys.uSERfullname],
                          //       //     ));
                          //     },
                          //   ),
                          // ),
                          SizedBox(
                            height: 9,
                          ),

                          Container(
                              color: Colors.white,
                              child: ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: MtCustomfontBoldSemi(
                                    color: Mycolors.black,
                                    text: getTranslatedForCurrentUser(
                                        context, 'xxlastseenxx'),
                                    fontsize: 15.6,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: MtCustomfontRegular(
                                    color: Mycolors.grey,
                                    text: agent!.lastSeen == true
                                        ? getTranslatedForCurrentUser(
                                            context, 'xxonlinexx')
                                        : agent!.lastSeen != true
                                            ? formatTimeDateCOMLPETEString(
                                                isdateTime: true,
                                                isshowutc: false,
                                                context: context,
                                                datetimetargetTime: DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        agent!.lastSeen))
                                            : '--',
                                    fontsize: 12.8,
                                  ),
                                ),
                                leading: Icon(
                                  Icons.access_time_rounded,
                                  color: Mycolors.primary,
                                ),
                                trailing: agent!.lastSeen == true
                                    ? myinkwell(
                                        onTap: AppConstants.isdemomode == true
                                            ? () {
                                                Utils.toast(
                                                    getTranslatedForCurrentUser(
                                                        context,
                                                        'xxxnotalwddemoxxaccountxx'));
                                              }
                                            : () {
                                                setAsOffline(context);
                                              },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: MtCustomfontBold(
                                            text: getTranslatedForCurrentUser(
                                                context, 'xxxsetasofflinexx'),
                                            fontsize: 12.6,
                                            color: Mycolors.primary,
                                          ),
                                        ),
                                      )
                                    : SizedBox(),
                                isThreeLine: false,
                                onTap: () {},
                              )),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                              color: Colors.white,
                              child: ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: MtCustomfontBoldSemi(
                                    color: Mycolors.black,
                                    text: getTranslatedForCurrentUser(
                                        context, 'xxxjoinedonxxx'),
                                    fontsize: 15.6,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: MtCustomfontRegular(
                                    color: Mycolors.grey,
                                    text: formatTimeDateCOMLPETEString(
                                        isdateTime: true,
                                        isshowutc: false,
                                        context: context,
                                        datetimetargetTime:
                                            DateTime.fromMillisecondsSinceEpoch(
                                          agent!.joinedOn,
                                        )),
                                    fontsize: 12.8,
                                  ),
                                ),
                                leading: Icon(
                                  Icons.access_time_rounded,
                                  color: Mycolors.primary,
                                ),
                                isThreeLine: false,
                                onTap: () {},
                              )),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                              color: Colors.white,
                              child: ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: MtCustomfontBoldSemi(
                                    color: Mycolors.black,
                                    text: getTranslatedForCurrentUser(
                                        context, 'xxxaccountcreatedbyxxx'),
                                    fontsize: 15.6,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: MtCustomfontRegular(
                                    color: Mycolors.grey,
                                    text: agent!.accountcreatedby == ""
                                        ? getTranslatedForCurrentUser(
                                            context, 'xxagentxx')
                                        : agent!.accountcreatedby,
                                    fontsize: 12.8,
                                  ),
                                ),
                                leading: Icon(
                                  Icons.person,
                                  color: Mycolors.primary,
                                ),
                                isThreeLine: false,
                                onTap: () {},
                              )),
                          SizedBox(
                            height: 18,
                          ),

                          agent!.deviceDetails.isEmpty
                              ? SizedBox()
                              : Container(
                                  margin: EdgeInsets.all(10),
                                  padding: EdgeInsets.fromLTRB(12, 20, 12, 20),
                                  decoration: boxDecoration(showShadow: true),
                                  child: Column(children: [
                                    MtCustomfontMedium(
                                      text: getTranslatedForCurrentUser(
                                          context, 'xxxuserdeviceindoxxx'),
                                      color: Mycolors.primary,
                                      fontsize: 15,
                                    ),
                                    myvhorizontaldivider(
                                        width: w, marginheight: 14),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.phone_iphone,
                                                color: Mycolors.secondary,
                                                size: 22,
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              MtCustomfontRegular(
                                                text: agent!.deviceDetails[Dbkeys
                                                        .deviceInfoMANUFACTURER] +
                                                    ' ' +
                                                    agent!.deviceDetails[
                                                        Dbkeys.deviceInfoMODEL],
                                                color: Mycolors.grey,
                                                fontsize: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // agent.deviceDetails[Dbkeys.deviceInfoOS] ==
                                        //         'android'
                                        //     ? Icon(
                                        //         Icons.android,
                                        //         color: Color(0xFFA0C034),
                                        //       )
                                        //     : Image.asset(
                                        //         'assets/COMMON_ASSETS/apple.png',
                                        //         height: 20,
                                        //       ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .check_circle_outline_rounded,
                                                color: Mycolors.secondary,
                                                size: 22,
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              MtCustomfontRegular(
                                                text: getTranslatedForCurrentUser(
                                                    context,
                                                    'xxxphysicalrealdevicexxx'),
                                                color: Mycolors.grey,
                                                fontsize: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                color: Mycolors.secondary,
                                                size: 21,
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              MtCustomfontRegular(
                                                text: '${getTranslatedForCurrentUser(context, 'xxxlastloginxxx')} - ' +
                                                    formatTimeDateCOMLPETEString(
                                                        context: context,
                                                        isdateTime: true,
                                                        datetimetargetTime: DateTime
                                                            .fromMillisecondsSinceEpoch(
                                                                agent!.deviceDetails[
                                                                    Dbkeys
                                                                        .deviceInfoLOGINTIMESTAMP])),
                                                color: Mycolors.grey,
                                                fontsize: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]),
                                ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            color: Colors.white,
                            child: ListTile(
                              title: MtCustomfontMedium(
                                fontsize: 16,
                                color: Mycolors.black,
                                text: 'Firebase UID',
                              ),

                              subtitle: MtCustomfontRegular(
                                text: AppConstants.isdemomode == true
                                    ? '******************'
                                    : agent!.firebaseuid,
                                fontsize: 13,
                              ),
                              trailing: Icon(Icons.copy_outlined),
                              leading: Icon(
                                EvaIcons.personDoneOutline,
                                color: Mycolors.primary,
                              ),
                              // isThreeLine: true,
                              onTap: AppConstants.isdemomode == true
                                  ? () {
                                      Utils.toast(getTranslatedForCurrentUser(
                                          context,
                                          'xxxnotalwddemoxxaccountxx'));
                                    }
                                  : () async {
                                      Clipboard.setData(new ClipboardData(
                                        text: agent!.firebaseuid,
                                      ));
                                      Utils.toast('Copied to Clipboard');
                                    },
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),

                          Container(
                              color: Colors.white,
                              child: ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: MtCustomfontBoldSemi(
                                    color: Mycolors.black,
                                    text: getTranslatedForCurrentUser(
                                        context, 'xxcurrentloginstxxx'),
                                    fontsize: 15.6,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: MtCustomfontBoldSemi(
                                    color: agent!.currentDeviceID == ""
                                        ? Mycolors.red
                                        : Mycolors.onlinetag,
                                    text: agent!.currentDeviceID == ""
                                        ? getTranslatedForCurrentUser(
                                            context, 'xxxloggedoutxxx')
                                        : getTranslatedForCurrentUser(
                                            context, 'xxxloggedinxxx'),
                                    fontsize: 12.8,
                                  ),
                                ),
                                trailing: agent!.currentDeviceID == ""
                                    ? SizedBox()
                                    : myinkwell(
                                        onTap: AppConstants.isdemomode == true
                                            ? () {
                                                Utils.toast(
                                                    getTranslatedForCurrentUser(
                                                        context,
                                                        'xxxnotalwddemoxxaccountxx'));
                                              }
                                            : () {
                                                String currentdeviceName = agent!
                                                        .deviceDetails.isEmpty
                                                    ? "UnKnown Device"
                                                    : agent!.deviceDetails[Dbkeys
                                                            .deviceInfoMANUFACTURER] +
                                                        ' ' +
                                                        agent!.deviceDetails[
                                                            Dbkeys
                                                                .deviceInfoMODEL];

                                                ShowConfirmWithInputTextDialog()
                                                    .open(
                                                        context: context,
                                                        title: getTranslatedForCurrentUser(
                                                            context,
                                                            'xxxforcelogoutxxx'),
                                                        controller: _name,
                                                        subtitle:
                                                            getTranslatedForCurrentUser(
                                                                context,
                                                                'xxxforcelogoutdescxxx'),
                                                        rightbtntext:
                                                            getTranslatedForCurrentUser(
                                                                    context,
                                                                    'xxlogoutxx')
                                                                .toUpperCase(),
                                                        rightbtnonpress:
                                                            AppConstants.isdemomode ==
                                                                    true
                                                                ? () {
                                                                    Utils.toast(getTranslatedForCurrentUser(
                                                                        context,
                                                                        'xxxnotalwddemoxxaccountxx'));
                                                                  }
                                                                : () async {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    ShowLoading().open(
                                                                        context:
                                                                            context,
                                                                        key:
                                                                            _keyLoader);
                                                                    await Utils.sendDirectNotification(
                                                                        title: getTranslatedForCurrentUser(context,
                                                                            'xxxaccountloggedoutxxx'),
                                                                        parentID:
                                                                            "AGENT--${agent!.id}",
                                                                        plaindesc: _name.text.trim().length <
                                                                                1
                                                                            ? getTranslatedForCurrentUser(context, 'xxxaccountforcedloggedoutxxx').replaceAll('(####)',
                                                                                '$currentdeviceName')
                                                                            : getTranslatedForCurrentUser(context, 'xxxaccountforcedloggedoutxxx').replaceAll('(####)', '$currentdeviceName') +
                                                                                "${getTranslatedForCurrentUser(context, 'xxreasonxxx')} ${_name.text.trim()}",
                                                                        docRef: FirebaseFirestore
                                                                            .instance
                                                                            .collection(DbPaths.collectionagents)
                                                                            .doc(agent!.id)
                                                                            .collection(DbPaths.agentnotifications)
                                                                            .doc(DbPaths.agentnotifications),
                                                                        postedbyID: 'Admin');
                                                                    await colRef
                                                                        .doc(agent!
                                                                            .id)
                                                                        .update({
                                                                      Dbkeys.currentDeviceID:
                                                                          "",
                                                                      Dbkeys.notificationTokens:
                                                                          []
                                                                    });
                                                                    await FirebaseApi
                                                                        .runTransactionRecordActivity(
                                                                      parentid:
                                                                          "AGENT--${agent!.id}",
                                                                      title: getTranslatedForCurrentUser(
                                                                          context,
                                                                          'xxxaccountloggedoutxxx'),
                                                                      postedbyID:
                                                                          "sys",
                                                                      onErrorFn:
                                                                          (e) {
                                                                        ShowLoading().close(
                                                                            key:
                                                                                _keyLoader,
                                                                            context:
                                                                                context);
                                                                        Utils.toast(
                                                                            "${getTranslatedForCurrentUser(context, 'xxxfailedntryagainxxx')} ERROR: $e");
                                                                      },
                                                                      onSuccessFn:
                                                                          () async {
                                                                        ShowLoading().close(
                                                                            key:
                                                                                _keyLoader,
                                                                            context:
                                                                                context);
                                                                        await fetchAgent(
                                                                            agentId:
                                                                                agent!.id);

                                                                        Utils.toast(getTranslatedForCurrentUser(
                                                                            context,
                                                                            'xxxuserloggedoutxxx'));
                                                                      },
                                                                      styledDesc:
                                                                          '<bold>${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxidxx')} ${agent!.id}</bold> ${getTranslatedForCurrentUser(context, 'xxxaccountforcedloggedoutxxx').replaceAll('(####)', '<bold>$currentdeviceName</bold>')}',
                                                                      plainDesc:
                                                                          '${getTranslatedForCurrentUser(context, 'xxagentxx')} ${getTranslatedForCurrentUser(context, 'xxidxx')} ${agent!.id} ${getTranslatedForCurrentUser(context, 'xxxaccountforcedloggedoutxxx').replaceAll('(####)', '$currentdeviceName')}',
                                                                    );
                                                                  });
                                              },
                                        child: MtCustomfontBold(
                                          text: getTranslatedForCurrentUser(
                                              context, 'xxxforcelogoutxxx'),
                                          color: Mycolors.red,
                                          fontsize: 13,
                                        ),
                                      ),
                                leading: Icon(
                                  Icons.key,
                                  color: Mycolors.primary,
                                ),
                                isThreeLine: false,
                                onTap: () {},
                              )),
                          SizedBox(
                            height: 10,
                          ),

                          agent!.currentDeviceID == ""
                              ? SizedBox()
                              : Container(
                                  color: Colors.white,
                                  child: ListTile(
                                    title: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: MtCustomfontBoldSemi(
                                        color: Mycolors.black,
                                        text: getTranslatedForCurrentUser(
                                            context, 'xxnotificationstatusxxx'),
                                        fontsize: 15.6,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: MtCustomfontBoldSemi(
                                        color: agent!.notificationTokens == []
                                            ? Mycolors.pink
                                            : Mycolors.onlinetag,
                                        text: agent!.notificationTokens == []
                                            ? getTranslatedForCurrentUser(
                                                    context, 'xxxmutedxxx')
                                                .toUpperCase()
                                            : getTranslatedForCurrentUser(
                                                    context, 'xxactivexx')
                                                .toUpperCase(),
                                        fontsize: 12.8,
                                      ),
                                    ),
                                    leading: Icon(
                                      Icons.notifications,
                                      color: Mycolors.primary,
                                    ),
                                    isThreeLine: false,
                                    onTap: () {},
                                  )),

                          SizedBox(
                            height: 30,
                          ),
                        ],
                      ))))),
    );
  }
}
