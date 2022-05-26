import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' as arch;
import 'package:komodo_dex/app_config/app_config.dart';
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
import 'package:komodo_dex/model/wallet_security_settings_provider.dart';
import 'package:komodo_dex/screens/authentification/disclaimer_page.dart';
import 'package:komodo_dex/screens/authentification/lock_screen.dart';
import 'package:komodo_dex/screens/authentification/pin_page.dart';
import 'package:komodo_dex/screens/authentification/show_delete_wallet_confirmation.dart';
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
import 'package:komodo_dex/widgets/build_red_dot.dart';
import 'package:komodo_dex/widgets/custom_simple_dialog.dart';
import 'package:komodo_dex/widgets/shared_preferences_builder.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String version = '';
  CexProvider cexProvider;
  WalletSecuritySettingsProvider walletSecuritySettingsProvider;

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
    walletSecuritySettingsProvider =
        context.watch<WalletSecuritySettingsProvider>();
    // final Locale myLocale = Localizations.localeOf(context);
    // Log('setting_page:67', 'current locale: $myLocale');
    return LockScreen(
      context: context,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).settings.toUpperCase(),
            key: const Key('settings-title'),
          ),
          elevation: Theme.of(context).brightness == Brightness.light ? 3 : 0,
        ),
        body: ListView(
          key: const Key('settings-scrollable'),
          children: <Widget>[
            _buildTitle(AppLocalizations.of(context).logoutsettings),
            _buildLogOutOnExit(),
            _buildTitle(AppLocalizations.of(context).soundTitle),
            _buildSound(),
            _buildTitle(AppLocalizations.of(context).security),
            _buildActivatePIN(),
            const SizedBox(height: 1),
            _buildActivateBiometric(),
            const SizedBox(height: 1),
            _buildCamouflagePin(),
            const SizedBox(height: 1),
            _buildChangePIN(),
            const SizedBox(height: 1),
            _buildSendFeedback(),
            if (walletBloc.currentWallet != null) ...[
              _buildTitle(AppLocalizations.of(context).backupTitle),
              _buildViewSeed(),
              const SizedBox(height: 1),
            ],
            _buildExport(),
            const SizedBox(height: 1),
            _buildImport(),
            const SizedBox(height: 1),
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
            if (appConfig.isUpdateCheckerEnabled) _buildUpdate(),
            const SizedBox(
              height: 48,
            ),
            if (walletBloc.currentWallet != null) _buildDeleteWallet(),
          ],
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
    return _chevronListTileHelper(
      title: Text(AppLocalizations.of(context).soundSettingsTitle),
      onTap: () => Navigator.push<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => SoundSettingsPage(),
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
    return SwitchListTile(
      title: Text(AppLocalizations.of(
        context,
      ).activateAccessPin),
      tileColor: Theme.of(context).primaryColor,
      value: walletSecuritySettingsProvider.activatePinProtection ?? false,
      onChanged: (
        bool switchValue,
      ) {
        Log(
          'setting_page:262',
          'switchValue $switchValue',
        );
        if (walletSecuritySettingsProvider.activatePinProtection) {
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
          walletSecuritySettingsProvider.activateBioProtection = false;
          walletSecuritySettingsProvider.activatePinProtection = false;
        } else {
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
        }
      },
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
          return SwitchListTile(
            title: Text(AppLocalizations.of(
              context,
            ).activateAccessBiometric),
            tileColor: Theme.of(context).primaryColor,
            value:
                walletSecuritySettingsProvider.activateBioProtection ?? false,
            onChanged: camoBloc.isCamoActive
                ? null
                : (
                    bool switchValue,
                  ) {
                    if (camoBloc.isCamoEnabled) {
                      _showCamoPinBioProtectionConflictDialog();
                      return;
                    }
                    if (walletSecuritySettingsProvider.activateBioProtection) {
                      walletSecuritySettingsProvider.activateBioProtection =
                          false;
                    } else {
                      authenticateBiometrics(
                        context,
                        PinStatus.DISABLED_PIN_BIOMETRIC,
                        authorize: true,
                      ).then((
                        bool passedBioCheck,
                      ) {
                        if (passedBioCheck) {
                          walletSecuritySettingsProvider.activateBioProtection =
                              true;
                          walletSecuritySettingsProvider.activatePinProtection =
                              true;
                          //
                        }
                      });
                    }
                  },
          );
        }
        return SizedBox();
      },
    );
  }

  void _showCamoPinBioProtectionConflictDialog() {
    dialogBloc.dialog = showDialog<dynamic>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CustomSimpleDialog(
            title: Text(
                AppLocalizations.of(context).camoPinBioProtectionConflictTitle),
            children: <Widget>[
              Text(AppLocalizations.of(context).camoPinBioProtectionConflict),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context).warningOkBtn),
                  ),
                ],
              ),
            ],
          );
        }).then((dynamic _) {
      dialogBloc.dialog = null;
    });
  }

  Widget _buildCamouflagePin() {
    return StreamBuilder<bool>(
        initialData: camoBloc.isCamoActive,
        stream: camoBloc.outIsCamoActive,
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.data == true) return SizedBox();

          return _chevronListTileHelper(
            title: Text(AppLocalizations.of(context).camoPinLink),
            onTap: () {
              Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                      settings: const RouteSettings(name: '/camoSetup'),
                      builder: (BuildContext context) => CamoPinSetupPage()));
            },
          );
        });
  }

  Widget _buildChangePIN() {
    return _chevronListTileHelper(
      title: Text(AppLocalizations.of(context).changePin),
      onTap: () => Navigator.push<dynamic>(
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
    );
  }

  Widget _buildSendFeedback() {
    return _chevronListTileHelper(
      title: Text(AppLocalizations.of(context).feedback),
      onTap: () => _shareFileDialog(),
    );
  }

  Widget _buildViewSeed() {
    return _chevronListTileHelper(
      title: Text(AppLocalizations.of(context).viewSeedAndKeys),
      onTap: () {
        Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => ViewSeedUnlockPage()));
      },
    );
  }

  Widget _buildExport() {
    return _chevronListTileHelper(
      title: Text(AppLocalizations.of(context).exportLink),
      onTap: () {
        Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => ExportPage()));
      },
    );
  }

  Widget _buildImport() {
    return _chevronListTileHelper(
      title: Text(AppLocalizations.of(context).importLink),
      onTap: () {
        Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => ImportPage()));
      },
    );
  }

  Widget _buildImportSwap() {
    return _chevronListTileHelper(
      title: Text(AppLocalizations.of(context).importSingleSwapLink),
      onTap: () {
        Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => ImportSwapPage()));
      },
    );
  }

  Widget _buildDisclaimerToS() {
    return _chevronListTileHelper(
        title: Text(AppLocalizations.of(context).disclaimerAndTos),
        onTap: () {
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

    return _chevronListTileHelper(
      title: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Text(AppLocalizations.of(context).checkForUpdates),
          if (updatesProvider.status != UpdateStatus.upToDate)
            buildRedDot(context, right: -12),
        ],
      ),
      onTap: () {
        Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => UpdatesPage(
                    refresh: true,
                    onSkip: () => Navigator.pop(context),
                  )),
        );
      },
    );
  }

  Widget _buildLogOutOnExit() {
    return SharedPreferencesBuilder<dynamic>(
      pref: 'switch_pin_log_out_on_exit',
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return SwitchListTile(
          value: snapshot.data ?? false,
          onChanged: (bool dataSwitch) {
            setState(() {
              SharedPreferences.getInstance().then((SharedPreferences data) {
                data.setBool('switch_pin_log_out_on_exit', dataSwitch);
              });
            });
          },
          title: Text(AppLocalizations.of(context).logoutOnExit),
          tileColor: Theme.of(context).primaryColor,
        );
      },
    );
  }

  Widget _buildDeleteWallet() {
    return ListTile(
      tileColor: Theme.of(context).errorColor,
      leading: Padding(
        padding: const EdgeInsets.all(6.0),
        child: SvgPicture.asset(
          'assets/svg/delete_setting.svg',
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      title: Text(
        AppLocalizations.of(context).deleteWallet,
        style: Theme.of(context)
            .textTheme
            .subtitle1
            .copyWith(color: Theme.of(context).colorScheme.onError),
      ),
      onTap: () => _showDialogDeleteWallet(),
    );
  }

  ListTile _chevronListTileHelper({
    @required Widget title,
    GestureTapCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      trailing: Icon(Icons.chevron_right),
      title: title,
      tileColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildEnableTestCoins() {
    return StreamBuilder(
      initialData: settingsBloc.enableTestCoins,
      stream: settingsBloc.outEnableTestCoins,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        return SwitchListTile(
          title: Text(AppLocalizations.of(context).enableTestCoins),
          value: snapshot.data ?? false,
          onChanged: (bool dataSwitch) {
            settingsBloc.setEnableTestCoins(dataSwitch);
          },
          tileColor: Theme.of(context).primaryColor,
        );
      },
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
                  showDeleteWalletConfirmation(
                    context,
                    password: password,
                  );
                },
              )),
    );
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
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    key: const Key('setting-share-button'),
                    onPressed: _shareLogs,
                    child: Text(
                      AppLocalizations.of(context).share,
                      style: Theme.of(context)
                          .textTheme
                          .button
                          .copyWith(color: Colors.white),
                    ),
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

class ShowLoadingDelete extends StatefulWidget {
  @override
  _ShowLoadingDeleteState createState() => _ShowLoadingDeleteState();
}

class _ShowLoadingDeleteState extends State<ShowLoadingDelete> {
  @override
  Widget build(BuildContext context) {
    return CustomSimpleDialog(
      children: <Widget>[
        Center(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(
              width: 16,
            ),
            Text(AppLocalizations.of(context).deletingWallet)
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
    return ListTile(
      trailing: ElevatedButton(
        onPressed: () {
          for (File f in _listLogs) {
            f.deleteSync();
          }
          _update();
        },
        child: Text(AppLocalizations.of(context).oldLogsDelete),
      ),
      title: Text(AppLocalizations.of(context).oldLogsUsed +
          ': ' +
          (_sizeMb >= 1000
              ? '${(_sizeMb / 1000).toStringAsFixed(2)} GB'
              : ' ${_sizeMb.toStringAsFixed(2)} MB')),
      tileColor: Theme.of(context).primaryColor,
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
