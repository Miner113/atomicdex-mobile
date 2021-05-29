import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' as arch;
import 'package:komodo_dex/blocs/camo_bloc.dart';
import 'package:komodo_dex/model/cex_provider.dart';
import 'package:komodo_dex/model/swap.dart';
import 'package:komodo_dex/model/swap_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:komodo_dex/blocs/authenticate_bloc.dart';
import 'package:komodo_dex/blocs/dialog_bloc.dart';
import 'package:komodo_dex/blocs/main_bloc.dart';
import 'package:komodo_dex/blocs/settings_bloc.dart';
import 'package:komodo_dex/blocs/wallet_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/updates_provider.dart';
import 'package:komodo_dex/screens/authentification/disclaimer_page.dart';
import 'package:komodo_dex/screens/authentification/lock_screen.dart';
import 'package:komodo_dex/screens/authentification/pin_page.dart';
import 'package:komodo_dex/screens/authentification/unlock_wallet_page.dart';
import 'package:komodo_dex/screens/import-export/export_page.dart';
import 'package:komodo_dex/screens/import-export/import_page.dart';
import 'package:komodo_dex/screens/import-export/import_swap_page.dart';
import 'package:komodo_dex/screens/settings/camo_pin_setup_page.dart';
import 'package:komodo_dex/screens/settings/sound_settings_page.dart';
import 'package:komodo_dex/screens/settings/updates_page.dart';
import 'package:komodo_dex/screens/settings/view_seed_unlock_page.dart';
import 'package:komodo_dex/services/mm_service.dart';
import 'package:komodo_dex/utils/log.dart';
import 'package:komodo_dex/utils/utils.dart';
import 'package:komodo_dex/widgets/buildRedDot.dart';
import 'package:komodo_dex/widgets/custom_simple_dialog.dart';
import 'package:komodo_dex/widgets/primary_button.dart';
import 'package:komodo_dex/widgets/secondary_button.dart';
import 'package:komodo_dex/widgets/shared_preferences_builder.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info/package_info.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String version = '';
  CexProvider cexProvider;

  @override
  void initState() {
    _getVersionApplication().then((String onValue) {
      setState(() {
        version = onValue;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    mainBloc.isUrlLaucherIsOpen = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    cexProvider = Provider.of<CexProvider>(context);
    // final Locale myLocale = Localizations.localeOf(context);
    // Log('setting_page:67', 'current locale: $myLocale');
    return LockScreen(
      context: context,
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).settings.toUpperCase(),
            key: const Key('settings-title'),
          ),
          centerTitle: true,
          elevation: settingsBloc.isLightTheme ? 3 : 0,
        ),
        body: Theme(
          data: Theme.of(context).copyWith(
              canvasColor: Theme.of(context).primaryColor,
              textTheme: Theme.of(context).textTheme),
          child: Container(
            child: ListView(
              key: const Key('settings-scrollable'),
              children: <Widget>[
                _buildTitle(AppLocalizations.of(context).logoutsettings),
                _buildLogOutOnExit(),
                _buildTitle(AppLocalizations.of(context).soundTitle),
                _buildSound(),
                _buildTitle(AppLocalizations.of(context).security),
                _buildActivatePIN(),
                const SizedBox(
                  height: 1,
                ),
                _buildActivateBiometric(),
                _buildCamouflagePin(),
                const SizedBox(
                  height: 1,
                ),
                _buildChangePIN(),
                const SizedBox(
                  height: 1,
                ),
                _buildSendFeedback(),
                walletBloc.currentWallet != null
                    ? _buildTitle(AppLocalizations.of(context).backupTitle)
                    : Container(),
                walletBloc.currentWallet != null
                    ? _buildViewSeed()
                    : Container(),
                _buildExport(),
                _buildImport(),
                _buildImportSwap(),
                const SizedBox(
                  height: 1,
                ),
                _buildTitle(AppLocalizations.of(context).oldLogsTitle),
                BuildOldLogs(),
                _buildTitle(AppLocalizations.of(context).legalTitle),
                _buildDisclaimerToS(),
                _buildTitle(AppLocalizations.of(context).developerTitle),
                _buildEnableTestCoins(),
                _buildTitle(version),
                _buildUpdate(),
                const SizedBox(
                  height: 48,
                ),
                walletBloc.currentWallet != null
                    ? _buildDeleteWallet()
                    : Container(),
                const SizedBox(
                  height: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _getVersionApplication() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version =
        AppLocalizations.of(context).version + ' : ' + packageInfo.version;

    version += ' - ${mmSe.mmVersion}';

    return version;
  }

  Widget _buildSound() {
    return CustomTile(
      onPressed: () {
        Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => SoundSettingsPage()));
      },
      child: ListTile(
        trailing: Icon(Icons.chevron_right,
            color:
                Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        title: Text(
          AppLocalizations.of(context).soundSettingsTitle,
          style: Theme.of(context).textTheme.bodyText2.copyWith(
              fontWeight: FontWeight.w300,
              color:
                  Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyText1,
      ),
    );
  }

  Widget _buildActivatePIN() {
    return CustomTile(
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                AppLocalizations.of(
                  context,
                ).activateAccessPin,
                style: Theme.of(
                  context,
                ).textTheme.bodyText2.copyWith(
                      fontWeight: FontWeight.w300,
                      color: Theme.of(context)
                          .textTheme
                          .bodyText2
                          .color
                          .withOpacity(0.7),
                    ),
              ),
            ),
            SharedPreferencesBuilder<dynamic>(
              pref: 'switch_pin',
              builder: (
                BuildContext context,
                AsyncSnapshot<dynamic> snapshot,
              ) {
                return snapshot.hasData
                    ? Switch(
                        value: snapshot.data,
                        key: const Key(
                          'settings-activate-pin',
                        ),
                        onChanged: (
                          bool switchValue,
                        ) {
                          Log(
                            'setting_page:262',
                            'switchValue $switchValue',
                          );
                          if (snapshot.data) {
                            // We want to deactivate biometrics here
                            // together with a regular pin protection,
                            // so that user would not leave himself
                            // only with biometrics one - thinking that
                            // he is "protected", truth be told
                            // without any fallback to regular pin
                            // protection, this biometrics widget is
                            // not very reliable (read very not)
                            // and it does not take too much time to
                            // break it, and get access to users funds.
                            SharedPreferences.getInstance().then((
                              SharedPreferences data,
                            ) {
                              data.setBool(
                                'switch_pin_biometric',
                                false,
                              );
                            });
                            Navigator.push<dynamic>(
                              context,
                              MaterialPageRoute<dynamic>(
                                builder: (
                                  BuildContext context,
                                ) =>
                                    LockScreen(
                                  context: context,
                                  pinStatus: PinStatus.DISABLED_PIN,
                                ),
                              ),
                            ).then((dynamic _) => setState(() {}));
                          } else {
                            SharedPreferences.getInstance().then((
                              SharedPreferences data,
                            ) {
                              data.setBool(
                                'switch_pin',
                                switchValue,
                              );
                            });
                            setState(() {});
                          }
                        })
                    : Container();
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActivateBiometric() {
    return FutureBuilder<bool>(
        initialData: false,
        future: canCheckBiometrics,
        builder: (
          BuildContext context,
          AsyncSnapshot<bool> snapshot,
        ) {
          if (snapshot.hasData && snapshot.data) {
            return CustomTile(
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).activateAccessBiometric,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyText2.copyWith(
                              fontWeight: FontWeight.w300,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyText2
                                  .color
                                  .withOpacity(0.7),
                            ),
                      ),
                    ),
                    SharedPreferencesBuilder<dynamic>(
                      pref: 'switch_pin_biometric',
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<dynamic> snapshot,
                      ) {
                        return snapshot.hasData
                            ? Switch(
                                value: snapshot.data,
                                onChanged: (
                                  bool switchValue,
                                ) {
                                  if (snapshot.data) {
                                    authenticateBiometrics(
                                      context,
                                      PinStatus.DISABLED_PIN_BIOMETRIC,
                                    ).then((
                                      bool passedBioCheck,
                                    ) {
                                      if (passedBioCheck) {
                                        SharedPreferences.getInstance().then((
                                          SharedPreferences data,
                                        ) {
                                          data.setBool(
                                            'switch_pin_biometric',
                                            false,
                                          );
                                          setState(() {});
                                        });
                                      }
                                    });
                                  } else {
                                    SharedPreferences.getInstance().then((
                                      SharedPreferences data,
                                    ) {
                                      data.setBool(
                                        'switch_pin_biometric',
                                        switchValue,
                                      );
                                      if (switchValue) {
                                        // Same situation here as above
                                        // on line 244 but from a
                                        // different angle. Just trying
                                        // to protect users from unreliable
                                        // !biometrics only! state.
                                        data.setBool(
                                          'switch_pin',
                                          true,
                                        );
                                      }
                                    });
                                    setState(() {});
                                  }
                                })
                            : Container();
                      },
                    )
                  ],
                ),
              ),
            );
          } else {
            return Container();
          }
        });
  }

  Widget _buildCamouflagePin() {
    return StreamBuilder<bool>(
        initialData: camoBloc.isCamoActive,
        stream: camoBloc.outIsCamoActive,
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.data == true) return Container();

          return Column(
            children: <Widget>[
              const SizedBox(
                height: 1,
              ),
              CustomTile(
                onPressed: () {
                  Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                          settings: const RouteSettings(name: '/camoSetup'),
                          builder: (BuildContext context) =>
                              CamoPinSetupPage()));
                },
                child: ListTile(
                  trailing: Icon(Icons.chevron_right,
                      color: Theme.of(context)
                          .textTheme
                          .bodyText2
                          .color
                          .withOpacity(0.7)),
                  title: Text(
                    AppLocalizations.of(context).camoPinLink,
                    style: Theme.of(context).textTheme.bodyText2.copyWith(
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context)
                            .textTheme
                            .bodyText2
                            .color
                            .withOpacity(0.7)),
                  ),
                ),
              ),
            ],
          );
        });
  }

  Widget _buildChangePIN() {
    return CustomTile(
      onPressed: () => Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => UnlockWalletPage(
                    textButton: AppLocalizations.of(context).unlock,
                    wallet: walletBloc.currentWallet,
                    isSignWithSeedIsEnabled: false,
                    onSuccess: (_, String password) {
                      Navigator.push<dynamic>(
                          context,
                          MaterialPageRoute<dynamic>(
                              builder: (BuildContext context) => PinPage(
                                  title:
                                      AppLocalizations.of(context).lockScreen,
                                  subTitle: AppLocalizations.of(context)
                                      .enterOldPinCode,
                                  pinStatus: PinStatus.CHANGE_PIN,
                                  password: password)));
                    },
                  ))),
      child: ListTile(
        trailing: Icon(Icons.chevron_right,
            color:
                Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        title: Text(
          AppLocalizations.of(context).changePin,
          style: Theme.of(context).textTheme.bodyText2.copyWith(
              fontWeight: FontWeight.w300,
              color:
                  Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildSendFeedback() {
    return CustomTile(
      onPressed: () => _shareFileDialog(),
      child: ListTile(
        key: const Key('setting-title-feedback'),
        trailing: Icon(Icons.chevron_right,
            color:
                Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        title: Text(
          AppLocalizations.of(context).feedback,
          style: Theme.of(context).textTheme.bodyText2.copyWith(
              fontWeight: FontWeight.w300,
              color:
                  Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildViewSeed() {
    return CustomTile(
      onPressed: () {
        Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => ViewSeedUnlockPage()));
      },
      child: ListTile(
        trailing: Icon(Icons.chevron_right,
            color:
                Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        title: Text(
          AppLocalizations.of(context).viewSeedAndKeys,
          style: Theme.of(context).textTheme.bodyText2.copyWith(
              fontWeight: FontWeight.w300,
              color:
                  Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildExport() {
    return CustomTile(
      onPressed: () {
        Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => ExportPage()));
      },
      child: ListTile(
        trailing: Icon(Icons.chevron_right,
            color:
                Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        title: Text(
          AppLocalizations.of(context).exportLink,
          style: Theme.of(context).textTheme.bodyText2.copyWith(
              fontWeight: FontWeight.w300,
              color:
                  Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildImport() {
    return CustomTile(
      onPressed: () {
        Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => ImportPage()));
      },
      child: ListTile(
        trailing: Icon(Icons.chevron_right,
            color:
                Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        title: Text(
          AppLocalizations.of(context).importLink,
          style: Theme.of(context).textTheme.bodyText2.copyWith(
              fontWeight: FontWeight.w300,
              color:
                  Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildImportSwap() {
    return CustomTile(
      onPressed: () {
        Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => ImportSwapPage()));
      },
      child: ListTile(
        trailing: Icon(Icons.chevron_right,
            color:
                Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        title: Text(
          AppLocalizations.of(context).importSingleSwapLink,
          style: Theme.of(context).textTheme.bodyText2.copyWith(
              fontWeight: FontWeight.w300,
              color:
                  Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildDisclaimerToS() {
    return CustomTile(
        child: ListTile(
          trailing: Icon(Icons.chevron_right,
              color:
                  Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
          title: Text(
            AppLocalizations.of(context).disclaimerAndTos,
            style: Theme.of(context).textTheme.bodyText2.copyWith(
                fontWeight: FontWeight.w300,
                color: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .color
                    .withOpacity(0.7)),
          ),
        ),
        onPressed: () {
          Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => const DisclaimerPage(
                      readOnly: true,
                    )),
          );
        });
  }

  Widget _buildUpdate() {
    final UpdatesProvider updatesProvider =
        Provider.of<UpdatesProvider>(context);

    return CustomTile(
        child: ListTile(
          trailing: Icon(Icons.chevron_right,
              color:
                  Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
          title: Row(
            children: <Widget>[
              Stack(
                overflow: Overflow.visible,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context).checkForUpdates,
                    style: Theme.of(context).textTheme.bodyText2.copyWith(
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context)
                            .textTheme
                            .bodyText2
                            .color
                            .withOpacity(0.7)),
                  ),
                  if (updatesProvider.status != UpdateStatus.upToDate)
                    buildRedDot(context, right: -12),
                ],
              ),
            ],
          ),
        ),
        onPressed: () {
          Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => UpdatesPage(
                      refresh: true,
                      onSkip: () => Navigator.pop(context),
                    )),
          );
        });
  }

  Widget _buildLogOutOnExit() {
    return CustomTile(
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                AppLocalizations.of(context).logoutOnExit,
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context)
                        .textTheme
                        .bodyText2
                        .color
                        .withOpacity(0.7)),
              ),
            ),
            SharedPreferencesBuilder<dynamic>(
              pref: 'switch_pin_log_out_on_exit',
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                return snapshot.hasData
                    ? Switch(
                        value: snapshot.data,
                        onChanged: (bool dataSwitch) {
                          setState(() {
                            SharedPreferences.getInstance()
                                .then((SharedPreferences data) {
                              data.setBool(
                                  'switch_pin_log_out_on_exit', dataSwitch);
                            });
                          });
                        })
                    : Container();
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteWallet() {
    return CustomTile(
      onPressed: () => _showDialogDeleteWallet(),
      backgroundColor: Theme.of(context).errorColor.withOpacity(0.8),
      child: ListTile(
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: SvgPicture.asset('assets/svg/delete_setting.svg'),
        ),
        title: Text(AppLocalizations.of(context).deleteWallet,
            style: Theme.of(context).textTheme.bodyText2.copyWith(
                fontWeight: FontWeight.w300,
                color: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .color
                    .withOpacity(0.8))),
      ),
    );
  }

  Widget _buildEnableTestCoins() {
    return CustomTile(
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                AppLocalizations.of(context).enableTestCoins,
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context)
                        .textTheme
                        .bodyText2
                        .color
                        .withOpacity(0.7)),
              ),
            ),
            StreamBuilder(
              initialData: settingsBloc.enableTestCoins,
              stream: settingsBloc.outEnableTestCoins,
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                return snapshot.hasData
                    ? Switch(
                        value: snapshot.data,
                        onChanged: (bool dataSwitch) {
                          settingsBloc.setEnableTestCoins(dataSwitch);
                        },
                      )
                    : Container();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDialogDeleteWallet() {
    Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => UnlockWalletPage(
                textButton: AppLocalizations.of(context).unlock,
                wallet: walletBloc.currentWallet,
                isSignWithSeedIsEnabled: false,
                onSuccess: (_, String password) {
                  Navigator.of(context).pop();
                  dialogBloc.dialog = showDialog<dynamic>(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          backgroundColor: Colors.white,
                          title: Column(
                            children: <Widget>[
                              SvgPicture.asset('assets/svg/delete_wallet.svg'),
                              const SizedBox(
                                height: 16,
                              ),
                              Text(
                                AppLocalizations.of(context)
                                    .deleteWallet
                                    .toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headline6
                                    .copyWith(
                                        color: Theme.of(context).errorColor),
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                            ],
                          ),
                          children: <Widget>[
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(children: <InlineSpan>[
                                TextSpan(
                                    text: AppLocalizations.of(context)
                                        .settingDialogSpan1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText2
                                        .copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .color
                                                .withOpacity(0.8))),
                                TextSpan(
                                    text: walletBloc.currentWallet.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText2
                                        .copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .color
                                                .withOpacity(0.8),
                                            fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text: AppLocalizations.of(context)
                                        .settingDialogSpan2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText2
                                        .copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .color
                                                .withOpacity(0.8))),
                              ]),
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Center(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(children: <InlineSpan>[
                                  TextSpan(
                                      text: AppLocalizations.of(context)
                                          .settingDialogSpan3,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText2
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2
                                                  .color
                                                  .withOpacity(0.8))),
                                  TextSpan(
                                      text: AppLocalizations.of(context)
                                          .settingDialogSpan4,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText2
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2
                                                  .color
                                                  .withOpacity(0.8),
                                              fontWeight: FontWeight.bold)),
                                  TextSpan(
                                      text: AppLocalizations.of(context)
                                          .settingDialogSpan5,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText2
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2
                                                  .color
                                                  .withOpacity(0.8))),
                                ]),
                              ),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: SecondaryButton(
                                    text: AppLocalizations.of(context).cancel,
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    isDarkMode: false,
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child: PrimaryButton(
                                    text: AppLocalizations.of(context).delete,
                                    key: const Key('delete-wallet'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      settingsBloc.setDeleteLoading(true);
                                      _showLoadingDelete();
                                      await walletBloc.deleteSeedPhrase(
                                          password, walletBloc.currentWallet);
                                      await walletBloc.deleteCurrentWallet();
                                      settingsBloc.setDeleteLoading(false);
                                    },
                                    backgroundColor:
                                        Theme.of(context).errorColor,
                                    isDarkMode: false,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                          ],
                        );
                      }).then((dynamic _) {
                    dialogBloc.dialog = null;
                  });
                },
              )),
    );
  }

  void _showLoadingDelete() {
    dialogBloc.dialog = showDialog<dynamic>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ShowLoadingDelete();
        }).then((dynamic _) {
      dialogBloc.dialog = null;
    });
  }

  Future<void> _shareLogs() async {
    Navigator.of(context).pop();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String os = Platform.isAndroid ? 'Android' : 'iOS';

    final now = DateTime.now();
    final log = mmSe.currentLog(now: now);
    if (swapMonitor.swaps.isEmpty) await swapMonitor.update();
    try {
      log.sink.write('\n\n--- my recent swaps ---\n\n');
      for (Swap swap in swapMonitor.swaps) {
        final started = swap.started;
        if (started == null) continue;
        final tim = DateTime.fromMillisecondsSinceEpoch(started.timestamp);
        final delta = now.difference(tim);
        if (delta.inDays > 7) continue; // Skip old swaps.
        log.sink.write(json.encode(swap.toJson) + '\n\n');
      }
      log.sink.write('\n\n--- / my recent swaps ---\n\n');
      // TBD: Replace these with a pretty-printed metrics JSON
      log.sink.write('atomicDEX mobile ${packageInfo.version} $os\n');
      log.sink.write('mm_version ${mmSe.mmVersion} mm_date ${mmSe.mmDate}\n');
      log.sink.write('netid ${mmSe.netid}\n');
      await log.sink.flush();
    } catch (ex) {
      Log('setting_page:723', ex);
      log.sink.write('Error saving swaps: $ex');
    }

    // Discord attachment size limit is about 8 MiB
    // so we're trying to send but a portion of the latest log.
    // bzip2 encoder is too slow for some older phones.
    // gzip gives us a compression ratio of about 20%, allowing to send about 40 MiB of log.
    int start = 0;
    final raf = log.file.openSync();
    final end = raf.lengthSync();
    if (end > 33 * 1024 * 1024) start = end - 33 * 1024 * 1024;
    final buf = Uint8List(end - start);
    raf.setPositionSync(start);
    final got = await raf.readInto(buf);
    if (got != end - start) {
      throw Exception(
          'Error reading from log: start $start, end $end, got $got');
    }
    final af = File('${mmSe.filesPath}dex.log.gz');
    if (af.existsSync()) af.deleteSync();
    final enc = arch.GZipEncoder();
    Log('setting_page:745', 'Creating dex.log.gz out of $got log bytes…');
    af.writeAsBytesSync(enc.encode(buf));
    final len = af.lengthSync();
    Log('setting_page:748', 'Compression produced $len bytes.');

    mainBloc.isUrlLaucherIsOpen = true;
    await Share.shareFiles([af.path],
        mimeTypes: ['application/octet-stream'],
        subject: 'atomicDEX logs at ${DateTime.now().toIso8601String()}');
  }

  Future<void> _shareFileDialog() async {
    dialogBloc.dialog = showDialog<dynamic>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CustomSimpleDialog(
            title: Text(AppLocalizations.of(context).feedback),
            children: <Widget>[
              Text(AppLocalizations.of(context).warningShareLogs),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FlatButton(
                    child:
                        Text(AppLocalizations.of(context).cancel.toUpperCase()),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  RaisedButton(
                    key: const Key('setting-share-button'),
                    child: Text(
                      AppLocalizations.of(context).share.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .button
                          .copyWith(color: Colors.white),
                    ),
                    onPressed: () => _shareLogs(),
                  )
                ],
              ),
            ],
          );
        }).then((dynamic _) {
      dialogBloc.dialog = null;
    });
  }
}

class CustomTile extends StatefulWidget {
  const CustomTile({Key key, this.onPressed, this.backgroundColor, this.child})
      : super(key: key);

  final Widget child;
  final Function onPressed;
  final Color backgroundColor;

  @override
  _CustomTileState createState() => _CustomTileState();
}

class _CustomTileState extends State<CustomTile> {
  Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (widget.backgroundColor == null) {
      backgroundColor = Theme.of(context).primaryColor;
    } else {
      backgroundColor = widget.backgroundColor;
    }
    return Container(
      color: backgroundColor,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          child: widget.child,
        ),
      ),
    );
  }
}

class ShowLoadingDelete extends StatefulWidget {
  @override
  _ShowLoadingDeleteState createState() => _ShowLoadingDeleteState();
}

class _ShowLoadingDeleteState extends State<ShowLoadingDelete> {
  @override
  void initState() {
    super.initState();
    settingsBloc.outIsDeleteLoading.listen((bool onData) {
      if (!onData) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: <Widget>[
        Center(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const <Widget>[
            CircularProgressIndicator(),
            SizedBox(
              width: 16,
            ),
            Text('Deleting wallet...')
          ],
        ))
      ],
    );
  }
}

class BuildOldLogs extends StatefulWidget {
  @override
  _BuildOldLogsState createState() => _BuildOldLogsState();
}

class _BuildOldLogsState extends State<BuildOldLogs> {
  List<dynamic> _listLogs = <dynamic>[];
  double _sizeMb = 0;

  @override
  void initState() {
    _update();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTile(
      child: ListTile(
        trailing: RaisedButton(
            child: Text(AppLocalizations.of(context).oldLogsDelete),
            onPressed: () {
              for (File f in _listLogs) {
                f.deleteSync();
              }
              _update();
            }),
        title: Text(
          AppLocalizations.of(context).oldLogsUsed +
              ': ' +
              (_sizeMb >= 1000
                  ? '${(_sizeMb / 1000).toStringAsFixed(2)} GB'
                  : ' ${_sizeMb.toStringAsFixed(2)} MB'),
          style: Theme.of(context).textTheme.bodyText2.copyWith(
              fontWeight: FontWeight.w300,
              color:
                  Theme.of(context).textTheme.bodyText2.color.withOpacity(0.7)),
        ),
      ),
    );
  }

  void _update() {
    _updateOldLogsList();
    _updateLogsSize();
  }

  void _updateOldLogsList() {
    final now = DateTime.now();
    final ymd = '${now.year}'
        '-${Log.twoDigits(now.month)}'
        '-${Log.twoDigits(now.day)}';
    final dirList = applicationDocumentsDirectorySync.listSync();
    setState(() {
      _listLogs = dirList
          .whereType<File>()
          .where((f) => f.path.endsWith('.log') && !f.path.endsWith('$ymd.log'))
          .toList();
    });
  }

  void _updateLogsSize() {
    int totalSize = 0;
    for (File log in _listLogs) {
      final fileSize = log.statSync().size;
      totalSize += fileSize;
    }
    setState(() {
      _sizeMb = totalSize / 1000000;
    });
  }
}
