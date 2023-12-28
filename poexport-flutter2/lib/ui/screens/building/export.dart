// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:cn_poe_export/basic/common.dart';
import 'package:cn_poe_export/creator/creator.dart';
import 'package:cn_poe_export/request/request.dart';
import 'package:cn_poe_export/request/type.dart';
import 'package:cn_poe_export/translator/translator.dart';
import 'package:cn_poe_export/ui/models/building/export.dart';
import 'package:cn_poe_export/ui/widgets/building/card_building_code.dart';
import 'package:cn_poe_export/ui/widgets/page.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import 'package:fluent_ui/fluent_ui.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> with PageMixin {
  bool isExpertMode = false;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(AppLocalizations.of(context)!.title_export),
        commandBar: ToggleSwitch(
          checked: isExpertMode,
          onChanged: (v) => setState(() => isExpertMode = v),
          content: Text(isExpertMode
              ? AppLocalizations.of(context)!.expert
              : AppLocalizations.of(context)!.simple),
        ),
      ),
      children: [
        isExpertMode ? const ExpertExportPage() : const SimpleExportPage()
      ],
    );
  }
}

class SimpleExportPage extends StatefulWidget {
  const SimpleExportPage({super.key});

  @override
  State<SimpleExportPage> createState() => _SimpleExportPageState();
}

class _SimpleExportPageState extends State<SimpleExportPage> {
  @override
  Widget build(BuildContext context) {
    final exportModel = context.read<SimpleExportModel>();
    var loadDisabled = context
        .select<SimpleExportModel, bool>((model) => model.accountName == "");
    var generateDisabled = context.select<SimpleExportModel, bool>(
        (model) => model.characterName == null);
    var leagues = context
        .select<SimpleExportModel, List<String>?>((model) => model.leagues);
    var shownCharacterNames = context.select<SimpleExportModel, List<String>?>(
        (model) => model.shownCharacterNames);
    var selectedLeague =
        context.select<SimpleExportModel, String?>((model) => model.league);
    var selectedCharacterName = context
        .select<SimpleExportModel, String?>((model) => model.characterName);
    var code =
        context.select<SimpleExportModel, String?>((model) => model.code);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoLabel(
          label: AppLocalizations.of(context)!.label_account,
          child: Row(
            children: [
              Expanded(
                child: TextFormBox(
                  initialValue: exportModel.accountName,
                  onChanged: (text) {
                    exportModel.accountName = text;
                  },
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.only(left: 5),
                child: FilledButton(
                  onPressed:
                      loadDisabled ? null : () => loadHandler(exportModel),
                  child: Text(AppLocalizations.of(context)!.button_load),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        InfoLabel(
          label: AppLocalizations.of(context)!.label_character,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ComboBox<String>(
                    value: selectedLeague,
                    items: leagues?.map<ComboBoxItem<String>>((e) {
                      return ComboBoxItem<String>(
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
                    onChanged: ((league) {
                      exportModel.league = league;
                    }),
                    placeholder:
                        Text(AppLocalizations.of(context)!.placeholder_league),
                  ),
                  const SizedBox(width: 10),
                  ComboBox<String>(
                    value: selectedCharacterName,
                    items: shownCharacterNames?.map<ComboBoxItem<String>>((e) {
                      return ComboBoxItem<String>(
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
                    onChanged: ((name) {
                      exportModel.characterName = name;
                    }),
                    placeholder: Text(
                        AppLocalizations.of(context)!.placeholder_character),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(left: 5),
                child: FilledButton(
                  onPressed: generateDisabled
                      ? null
                      : () => generateHandler(exportModel),
                  child: Text(AppLocalizations.of(context)!.button_generate),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CardBuildingCode(
          code: code,
        ),
      ],
    );
  }

  void loadHandler(SimpleExportModel exportModel) {
    exportModel.characters = null;

    requester.getCharacters(exportModel.accountName!, 'pc').then((value) {
      exportModel.loadedAccountName = exportModel.accountName;
      exportModel.characters = value;
    }).onError<ClientException>((error, stackTrace) {
      showError(context, AppLocalizations.of(context)!.error_no_internet, null);
    }).onError<RequestException>((error, stackTrace) {
      switch (error.errorType) {
        case RequestErrorType.unauthorized:
          showError(context, AppLocalizations.of(context)!.error_unauthorized,
              AppLocalizations.of(context)!.error_unauthorized_attachment);
        case RequestErrorType.forbidden:
          showError(context, AppLocalizations.of(context)!.error_forbidden,
              AppLocalizations.of(context)!.error_forbidden_attachment);
        case RequestErrorType.rateLimited:
          showError(context, AppLocalizations.of(context)!.error_rate_limited,
              AppLocalizations.of(context)!.error_rate_limited_attachment);
        default:
          showError(context, AppLocalizations.of(context)!.error_unknown,
              AppLocalizations.of(context)!.error_unknown_attachment);
      }
    });
  }

  void generateHandler(SimpleExportModel exportModel) async {
    exportModel.code = null;

    String items;
    String passiveSkills;
    try {
      items = await requester.getItems(
          exportModel.loadedAccountName!, exportModel.characterName!, "pc");
      passiveSkills = await requester.getPassiveSkills(
          exportModel.loadedAccountName!, exportModel.characterName!, "pc");
    } on ClientException catch (error) {
      showError(context, AppLocalizations.of(context)!.error_no_internet,
          error.message);
      return;
    } on RequestException catch (error) {
      switch (error.errorType) {
        case RequestErrorType.unauthorized:
          showError(context, AppLocalizations.of(context)!.error_unauthorized,
              AppLocalizations.of(context)!.error_unauthorized_attachment);
        case RequestErrorType.forbidden:
          showError(context, AppLocalizations.of(context)!.error_forbidden,
              AppLocalizations.of(context)!.error_forbidden_attachment);
        case RequestErrorType.rateLimited:
          showError(context, AppLocalizations.of(context)!.error_rate_limited,
              AppLocalizations.of(context)!.error_rate_limited_attachment);
        default:
          showError(context, AppLocalizations.of(context)!.error_unknown,
              AppLocalizations.of(context)!.error_unknown_attachment);
      }
      return;
    }

    items = await translator.translateItems(items);
    passiveSkills = await translator.translatePassiveSkills(passiveSkills);
    var building = await creator.createBuilding(items, passiveSkills);
    exportModel.code = _encode(building);
  }

  String _encode(String building) {
    var compressed = ZLibCodec().encode(utf8.encode(building));
    return base64Encode(compressed).replaceAll("+", "-").replaceAll("/", "_");
  }
}

class ExpertExportPage extends StatefulWidget {
  const ExpertExportPage({super.key});

  @override
  State<ExpertExportPage> createState() => _ExpertExportPageState();
}

class _ExpertExportPageState extends State<ExpertExportPage> with PageMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            "Expert mode change the pob file and you can use pob to import buildings."),
        SizedBox(height: 20),
        InfoLabel(
          label: 'Listening Port',
          child: Row(children: [
            Expanded(
                child: const TextBox(
              expands: false,
            )),
            const Spacer(),
            Button(child: const Text('Update'), onPressed: () {}),
          ]),
        ),
        SizedBox(height: 20),
        InfoLabel(
          label: 'Pob:',
          child: Row(children: [
            Expanded(
                child: Text(
                    "d:/d:/d:/d:/d:/d:/d:/d:/d:/d:/d:/d:/d:/d:/d:/d:/d:/",
                    overflow: TextOverflow.ellipsis)),
            const Spacer(),
          ]),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Button(child: const Text('Change'), onPressed: () {}),
            SizedBox(width: 10),
            Button(child: const Text('Need Update'), onPressed: () {}),
          ],
        ),
        subtitle(content: Text("URL Encoding"))
      ],
    );
  }
}
