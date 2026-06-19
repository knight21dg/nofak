import 'dart:convert';
import 'dart:developer';
import 'dart:io';


import 'package:dotted_border/dotted_border.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/custom_field/fetch_custom_fields_cubit.dart';
import 'package:nofak/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:nofak/data/model/category_model.dart';
import 'package:nofak/data/model/item/item_model.dart';
import 'package:nofak/data/model/system_settings_model.dart';
import 'package:nofak/data/model/user/user_model.dart';
import 'package:nofak/ui/screens/item/add_item_screen/select_category.dart';
import 'package:nofak/ui/screens/item/add_item_screen/widgets/image_adapter.dart';
import 'package:nofak/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:nofak/ui/screens/widgets/custom_text_form_field.dart';
import 'package:nofak/ui/screens/widgets/dynamic_field.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/cloud_state/cloud_state.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/helper_utils.dart';
import 'package:nofak/utils/hive_utils.dart';
import 'package:nofak/utils/image_picker.dart';
import 'package:nofak/ui/screens/item/add_item_screen/widgets/authenticity_dialog.dart';
import 'package:nofak/utils/recording_standards.dart';
import 'package:nofak/utils/slug_formatter.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AddItemDetails extends StatefulWidget {
  final List<CategoryModel>? breadCrumbItems;
  final bool? isEdit;

  const AddItemDetails({super.key, this.breadCrumbItems, required this.isEdit});

  static Route route(RouteSettings settings) {
    Map<String, dynamic>? arguments =
        settings.arguments as Map<String, dynamic>?;
    return MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          create: (context) => FetchCustomFieldsCubit(),
          child: AddItemDetails(
            breadCrumbItems: arguments?['breadCrumbItems'],
            isEdit: arguments?['isEdit'],
          ),
        );
      },
    );
  }

  @override
  CloudState<AddItemDetails> createState() => _AddItemDetailsState();
}

class _AddItemDetailsState extends CloudState<AddItemDetails>
    with TickerProviderStateMixin {
  final PickImage _pickTitleImage = PickImage();
  final PickImage itemImagePicker = PickImage();
  String titleImageURL = "";
  List<dynamic> mixedItemImageList = [];
  List<int> deleteItemImageList = [];
  late final GlobalKey<FormState> _formKey;

  // Shared fields
  final TextEditingController adSlugController = TextEditingController();
  final TextEditingController adPriceController = TextEditingController();
  final TextEditingController adPhoneNumberController = TextEditingController();
  final TextEditingController adAdditionalDetailsController =
      TextEditingController();
  final TextEditingController minSalaryController = TextEditingController();
  final TextEditingController maxSalaryController = TextEditingController();

  File? videoFile;
  String videoURL = "";

  // Language-specific fields
  Map<String, TextEditingController> adTitleControllers = {};
  Map<String, TextEditingController> adDescriptionControllers = {};

  int selectedLangIndex = 0;
  List languages = [];
  String defaultLangCode = '';
  TabController? _tabController;

  late List selectedCategoryList;
  ItemModel? item;

  // Flag to ensure translations are only populated once
  bool _translationsPopulated = false;

  final ValueNotifier<bool> _isValid = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _checkLostData();
    _formKey = GlobalKey<FormState>();
    AbstractField.fieldsData.clear();
    AbstractField.files.clear();
    if (widget.isEdit ?? false) {
      item = getCloudData('edit_request') as ItemModel;
      clearCloudData("item_details");
      clearCloudData("with_more_details");
      context.read<FetchCustomFieldsCubit>().fetchCustomFields(
            categoryIds: item!.allCategoryIds!,
          );

      // Fetch settings for initState use
      final settingsCubit = context.read<FetchSystemSettingsCubit>();
      languages = settingsCubit.getSetting(SystemSetting.language) as List? ?? [];
      defaultLangCode = settingsCubit.getSetting(SystemSetting.defaultLanguage) ?? '';

      // Set default language values
      adTitleControllers[defaultLangCode] = TextEditingController(
        text: item?.translatedName ?? "",
      );

      adSlugController.text = item?.slug ?? "";
      adDescriptionControllers[defaultLangCode] = TextEditingController(
        text: item?.translatedDescription ?? "",
      );

      // Store translations for later population when languages are available
      print("item?.translations***${item?.translations}");
      if (item?.translations != null) {
        // Store the translations data to populate later
        addCloudData("item_translations", item!.translations);
      }

      adPriceController.text = item?.price?.toString() ?? "";
      minSalaryController.text =
          item?.minSalary != null ? item?.minSalary.toString() ?? "" : "";
      maxSalaryController.text =
          item?.maxSalary != null ? item?.maxSalary.toString() ?? "" : "";
      adPhoneNumberController.text = item?.contact ?? "";
      videoURL = item?.videoLink ?? "";
      titleImageURL = item?.image ?? "";
      List<String?>? list = item?.galleryImages?.map((e) => e.image).toList();
      mixedItemImageList.addAll([...list ?? []]);
      setState(() {});
    } else {
      List<int> ids = widget.breadCrumbItems!.map((item) => item.id!).toList();
      context.read<FetchCustomFieldsCubit>().fetchCustomFields(
            categoryIds: ids.join(','),
          );
      selectedCategoryList = ids;
      adPhoneNumberController.text = HiveUtils.getUserDetails().mobile ?? "";
      
      final settingsCubit = context.read<FetchSystemSettingsCubit>();
      languages = settingsCubit.getSetting(SystemSetting.language) as List? ?? [];
      defaultLangCode = settingsCubit.getSetting(SystemSetting.defaultLanguage) ?? '';
      
      adTitleControllers[HiveUtils.getLanguage()['code']] =
          TextEditingController();

      _loadDraft();

      // Add listeners for auto-saving draft
      adSlugController.addListener(_saveDraft);
      adPriceController.addListener(_saveDraft);
      adPhoneNumberController.addListener(_saveDraft);
      adAdditionalDetailsController.addListener(_saveDraft);
      minSalaryController.addListener(_saveDraft);
      maxSalaryController.addListener(_saveDraft);
    }

    // --- Slug auto-generation logic ---
    // Will be set up in build() after languages are loaded

    _pickTitleImage.listener((p0) {
      titleImageURL = "";
      if (mounted) {
        setState(() {});
        _saveDraft();
      }
    });

    itemImagePicker.listener((images) {
      try {
        mixedItemImageList.addAll(List<dynamic>.from(images));
      } catch (e) {}

      if (mounted) {
        setState(() {});
        _saveDraft();
      }
    });

    // Check for lost data on startup (Handles Android app kills during camera use)
    _checkLostData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isValid.value = _formKey.currentState?.validate() ?? false;
    });
  }

  @override
  void dispose() {
    adSlugController.dispose();
    adPriceController.dispose();
    adPhoneNumberController.dispose();
    adAdditionalDetailsController.dispose();
    minSalaryController.dispose();
    maxSalaryController.dispose();
    _tabController?.dispose();
    _isValid.dispose();
    _pickTitleImage.dispose();
    itemImagePicker.dispose();

    for (final controller in [
      ...adDescriptionControllers.values,
      ...adTitleControllers.values,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  String generateSlug(String title) {
    // force lowercase
    String slug = title.toLowerCase();

    // replace anything that is NOT english letters a-z or digits 0-9 with "-"
    slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '-');

    // trim leading/trailing "-"
    slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');

    return slug;
  }

  bool isJobCategory() {
    return (widget.isEdit ?? false) && item!.category!.isJobCategory == 1 ||
        widget.breadCrumbItems != null &&
            widget.breadCrumbItems!.isNotEmpty &&
            widget.breadCrumbItems![0].isJobCategory == 1;
  }

  bool isPriceOptional() {
    return (widget.isEdit ?? false) && item!.category!.priceOptional == 1 ||
        widget.breadCrumbItems != null &&
            widget.breadCrumbItems!.isNotEmpty &&
            widget.breadCrumbItems![0].priceOptional == 1;
  }

  bool isTechnicianCategory() {
    // Check if the root category is technician marketplace or services
    if (widget.breadCrumbItems != null && widget.breadCrumbItems!.isNotEmpty) {
      String rootSlug = widget.breadCrumbItems![0].slug ?? "";
      String rootName = widget.breadCrumbItems![0].name?.toLowerCase() ?? "";
      return rootSlug == "technician-marketplace" || 
             rootName.contains("technician") ||
             rootSlug == "services" || 
             rootName.contains("service");
    }
    if (widget.isEdit == true && item?.category != null) {
       return item?.category?.slug == "technician-marketplace" || 
              (item?.category?.name?.toLowerCase().contains("technician") ?? false) ||
              item?.category?.slug == "services" || 
              (item?.category?.name?.toLowerCase().contains("service") ?? false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    languages =
        context.read<FetchSystemSettingsCubit>().getSetting(
              SystemSetting.language,
            )
            as List? ??
        [];
    // Set defaultLangCode from system settings
    defaultLangCode = context.read<FetchSystemSettingsCubit>().getSetting(
      SystemSetting.defaultLanguage,
    );

    // Ensure default language is first in the list (case-insensitive)
    if (languages.isNotEmpty &&
        (languages[0]['code']?.toString().toLowerCase() ?? '') !=
            (defaultLangCode.toLowerCase())) {
      final defIndex = languages.indexWhere(
        (l) =>
            (l['code']?.toString().toLowerCase() ?? '') ==
            defaultLangCode.toLowerCase(),
      );
      if (defIndex > 0) {
        final defLang = languages.removeAt(defIndex);
        languages.insert(0, defLang);
      }
    }
    if (languages.isEmpty) {
      return Center(child: Text('No languages available'));
    }
    _tabController ??= TabController(
      length: languages.length,
      vsync: this,
      initialIndex: 0,
    );
    // Initialize controllers for each language
    for (var lang in languages) {
      adTitleControllers[lang['code']] ??= TextEditingController();
      adDescriptionControllers[lang['code']] ??= TextEditingController();
    }

    // --- Slug auto-generation from English title ---
    final englishLang = languages.firstWhere(
      (lang) => (lang['code']?.toString().toLowerCase() ?? '') == 'en',
      orElse: () => null,
    );

    // Populate translations if in edit mode and not yet populated
    if ((widget.isEdit ?? false) && !_translationsPopulated) {
      if (item?.translations != null &&
          (item!.translations as List).isNotEmpty) {
        for (var lang in languages) {
          final langCode = lang['code'];
          final langId = lang['id'];
          var translation = (item!.translations as List).firstWhere(
            (t) => t is Map<String, dynamic> && t['language_id'] == langId,
            orElse: () => null,
          );
          if (translation != null && translation is Map<String, dynamic>) {
            adTitleControllers[langCode]?.text =
                translation['name'] ?? (item?.translatedName ?? "");
            adDescriptionControllers[langCode]?.text =
                translation['description'] ??
                (item?.translatedDescription ?? "");
          } else {
            // Fallback to default
            adTitleControllers[langCode]?.text = item?.name ?? "";
            adDescriptionControllers[langCode]?.text = item?.description ?? "";
          }
        }
        _translationsPopulated = true;
      } else {
        // If translations is blank, fill all with default, but ensure default language is always set
        for (var lang in languages) {
          final langCode = lang['code'];
          if (langCode == defaultLangCode) {
            adTitleControllers[langCode]?.text = item?.translatedName ?? "";
            adDescriptionControllers[langCode]?.text =
                item?.translatedDescription ?? "";
          } else {
            adTitleControllers[langCode]?.text = "";
            adDescriptionControllers[langCode]?.text = "";
          }
        }
        _translationsPopulated = true;
      }
    }

    String selectedLangCode = languages[selectedLangIndex]['code'];
    bool isDefault = selectedLangCode == defaultLangCode;

    return AnnotatedSafeArea(
      isAnnotated: true,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          return;
        },
        child: Scaffold(
          appBar: UiUtils.buildAppBar(
            context,
            showBackButton: true,
            title: "AdDetails".translate(context),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (languages.length > 1)
                Container(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: soldOutButtonColor,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ValueListenableBuilder(
                            valueListenable: _isValid,
                            builder: (context, value, child) {
                              return CustomText(
                                (value
                                        ? "allRequiredDefaultLangFilled"
                                        : "pleaseFillDefaultLangRequiredMsg")
                                    .translate(context),
                                color: soldOutButtonColor,
                                fontSize: context.font.normal,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                color: Colors.transparent,
                child: UiUtils.buildButton(
                  context,
                  outerPadding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  onPressed: () {
                    adSlugController.text = adSlugController.text.replaceAll(
                      RegExp(r'^-+|-+$'),
                      '',
                    );
                    _isValid.value = _formKey.currentState?.validate() ?? false;
                    if (_isValid.value) {
                      // Enforcement: Professional Introduction Video (Spec 4.3)
                      if (isTechnicianCategory()) {
                        UserModel user = HiveUtils.getUserDetails();
                        if (user.introductionVideo == null || user.introductionVideo!.isEmpty) {
                          UiUtils.showBlurredDialoge(
                            context,
                            dialoge: BlurredDialogBox(
                              title: "professionalIdRequired".translate(context),
                              content: CustomText(
                                "technicianIntroVideoWarning"
                                    .translate(context),
                              ),
                              acceptButtonName: "recordNow".translate(context),
                              onAccept: () async {
                                Navigator.pop(context); // Close dialog
                                Navigator.pushNamed(
                                  context,
                                  Routes.sellerIntroVerificationScreen,
                                  arguments: {
                                    "isResubmitted": false,
                                    "type": "technician",
                                  },
                                );
                              },
                            ),
                          );
                          return;
                        }
                      }

                      List<File>? galleryImages = mixedItemImageList
                          .where(
                            (element) => element != null && element is File,
                          )
                          .map((element) => element as File)
                          .toList();

                      // Build translations map for name and description (as strings, all language IDs present)
                      Map<String, Map<String, String>> translations = {};

                      for (var lang in languages) {
                        final langId = lang['id'].toString(); // e.g., "1", "2"
                        final langCode = lang['code']; // e.g., "en", "fr"

                        if (langCode == defaultLangCode)
                          continue; // Skip default language

                        final name =
                            adTitleControllers[langCode]?.text.trim() ?? '';
                        final description =
                            adDescriptionControllers[langCode]?.text.trim() ??
                            '';

                        final langTranslations = <String, String>{};

                        if (name.isNotEmpty) {
                          langTranslations['name'] = name;
                        }
                        if (description.isNotEmpty) {
                          langTranslations['description'] = description;
                        }

                        if (langTranslations.isNotEmpty) {
                          translations[langId] = langTranslations;
                        }
                      }

                      print("translations***$translations");

                      if (_pickTitleImage.pickedFile == null &&
                          titleImageURL == "") {
                        UiUtils.showBlurredDialoge(
                          context,
                          dialoge: BlurredDialogBox(
                            title: "imageRequired".translate(context),
                            content: CustomText(
                              "selectImageYourItem".translate(context),
                            ),
                          ),
                        );
                        return;
                      }

                      if (videoFile == null && videoURL == "") {
                        UiUtils.showBlurredDialoge(
                          context,
                          dialoge: BlurredDialogBox(
                            title: "videoRequired".translate(context),
                            content: CustomText(
                              "selectVideoYourItem".translate(context),
                            ),
                          ),
                        );
                        return;
                      }
                      Map<String, dynamic> itemDetailsData = {
                        "name": adTitleControllers[defaultLangCode]!.text,
                        "slug": adSlugController.text,
                        "description":
                            adDescriptionControllers[defaultLangCode]!.text,
                        if (widget.isEdit != true)
                          "category_id": selectedCategoryList.last,
                        if (widget.isEdit ?? false) "id": item?.id,
                        "price": adPriceController.text,
                        "contact": adPhoneNumberController.text,
                        "video_link": videoURL,
                        if (widget.isEdit ?? false)
                          "delete_item_image_id": deleteItemImageList.join(','),
                        "all_category_ids": (widget.isEdit ?? false)
                            ? item!.allCategoryIds
                            : selectedCategoryList.join(','),
                        if (isJobCategory())
                          "min_salary": minSalaryController.text,
                        if (isJobCategory())
                          "max_salary": maxSalaryController.text,
                        "translations": json.encode(translations),
                      };

                      addCloudData("item_details", itemDetailsData);

                      screenStack++;
                      if (context.read<FetchCustomFieldsCubit>().isEmpty()!) {
                        addCloudData("with_more_details", itemDetailsData);

                        Navigator.pushNamed(
                          context,
                          Routes.confirmLocationScreen,
                          arguments: {
                            "isEdit": widget.isEdit,
                            "mainImage": _pickTitleImage.pickedFile,
                            "otherImage": galleryImages,
                            "video": videoFile,
                          },
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          Routes.addMoreDetailsScreen,
                          arguments: {
                            "context": context,
                            "isEdit": widget.isEdit == true,
                            "mainImage": _pickTitleImage.pickedFile,
                            "otherImage": galleryImages,
                            "video": videoFile,
                          },
                        ).then((value) {
                          screenStack--;
                        });
                      }
                    }
                  },
                  height: 48,
                  fontSize: context.font.large,
                  buttonTitle: "next".translate(context),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (languages.length > 1)
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: context.color.territoryColor,
                      unselectedLabelColor: context.color.textColorDark
                          .withValues(alpha: 0.5),
                      indicatorColor: context.color.territoryColor,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabAlignment: TabAlignment.start,
                      onTap: (index) {
                        if (selectedLangIndex == index) {
                          _isValid.value =
                              _formKey.currentState?.validate() ?? true;
                          return;
                        }
                        // Only validate when leaving the default language tab (index 0)
                        if (selectedLangIndex == 0 && index != 0) {
                          _isValid.value =
                              _formKey.currentState?.validate() ?? false;
                          // Prevent tab change if not valid
                          if (!_isValid.value) {
                            _tabController?.animateTo(selectedLangIndex);
                            return;
                          }
                        }
                        setState(() {
                          selectedLangIndex = index;
                          _formKey.currentState?.reset();
                        });
                      },
                      tabs: languages.map((lang) {
                        final isDef = lang['code'] == defaultLangCode;
                        return Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Text(lang['name']),
                              ValueListenableBuilder(
                                valueListenable: _isValid,
                                builder: (context, value, child) {
                                  return value && isDef
                                      ? child!
                                      : const SizedBox.shrink();
                                },
                                child: Icon(
                                  Icons.check_box_rounded,
                                  color: context.color.territoryColor,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  SizedBox(height: 18),
                  CustomText(
                    "youAreAlmostThere".translate(context),
                    fontSize: context.font.large,
                    fontWeight: FontWeight.w600,
                    color: context.color.textColorDark,
                  ),
                  SizedBox(height: 16),
                  if (widget.breadCrumbItems != null)
                    SizedBox(
                      height: 20,
                      width: context.screenWidth,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            bool isNotLast =
                                (widget.breadCrumbItems!.length - 1) != index;
                            return Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    _onBreadCrumbItemTap(index);
                                  },
                                  child: CustomText(
                                    widget.breadCrumbItems![index].name!,
                                    color: isNotLast
                                        ? context.color.textColorDark
                                        : context.color.territoryColor,
                                    firstUpperCaseWidget: true,
                                  ),
                                ),
                                if (index < widget.breadCrumbItems!.length - 1)
                                  CustomText(
                                    " > ",
                                    color: context.color.territoryColor,
                                  ),
                              ],
                            );
                          },
                          itemCount: widget.breadCrumbItems!.length,
                        ),
                      ),
                    ),
                  SizedBox(height: 18),
                  CustomText(
                    isDefault
                        ? "adTitle".translate(context)
                        : "${'adTitle'.translate(context)} (${languages[selectedLangIndex]['name']})",
                  ),
                  SizedBox(height: 10),
                  CustomTextFormField(
                    controller: adTitleControllers[selectedLangCode],
                    validator: isDefault
                        ? CustomTextFieldValidator.nullCheck
                        : null,
                    onChange: (value) {
                      adSlugController.text = generateSlug(value);
                    },
                    action: TextInputAction.next,
                    capitalization: TextCapitalization.sentences,
                    hintText: isDefault
                        ? "adTitleHere".translate(context)
                        : "adTitleHere (${languages[selectedLangIndex]['name']})"
                              .translate(context),
                    hintTextStyle: TextStyle(
                      color: context.color.textDefaultColor.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: context.font.normal,
                    ),
                  ),
                  SizedBox(height: 15),
                  CustomText(
                    isDefault
                        ? "descriptionLbl".translate(context)
                        : "${'descriptionLbl'.translate(context)} (${languages[selectedLangIndex]['name']})",
                  ),
                  SizedBox(height: 15),
                  CustomTextFormField(
                    controller: adDescriptionControllers[selectedLangCode],
                    validator: isDefault
                        ? CustomTextFieldValidator.nullCheck
                        : null,
                    action: TextInputAction.newline,
                    capitalization: TextCapitalization.sentences,
                    hintText: isDefault
                        ? "writeSomething".translate(context)
                        : "writeSomething (${languages[selectedLangIndex]['name']})"
                              .translate(context),
                    maxLine: 100,
                    minLine: 6,
                    hintTextStyle: TextStyle(
                      color: context.color.textDefaultColor.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: context.font.normal,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      CustomText("mainPicture".translate(context)),
                      const SizedBox(width: 3),
                      CustomText(
                        "maxSize".translate(context),
                        fontStyle: FontStyle.italic,
                        fontSize: context.font.small,
                      ),
                    ],
                  ),
                  CustomText(
                    "recommendedSize".translate(context),
                    fontStyle: FontStyle.italic,
                    fontSize: context.font.small,
                    color: context.color.textLightColor.withValues(alpha: 0.4),
                  ),
                  SizedBox(height: 10),
                  Wrap(children: [...[], titleImageListener()]),
                  SizedBox(height: 10),
                  Row(
                    spacing: 3,
                    children: [
                      CustomText("otherPictures".translate(context)),
                      CustomText(
                        "max5Images".translate(context),
                        fontStyle: FontStyle.italic,
                        fontSize: context.font.small,
                      ),
                    ],
                  ),
                  CustomText(
                    "recommendedSize".translate(context),
                    fontStyle: FontStyle.italic,
                    fontSize: context.font.small,
                    color: context.color.textLightColor.withValues(alpha: 0.4),
                  ),
                  SizedBox(height: 10),
                  itemImagesListener(),
                  SizedBox(height: 10),
                  CustomText(
                    isJobCategory()
                        ? "salary".translate(context)
                        : "price".translate(context),
                  ),
                  SizedBox(height: 10),
                  isJobCategory()
                      ? buildSalaryRange()
                      : CustomTextFormField(
                          controller: adPriceController,
                          action: TextInputAction.next,
                          fixedPrefix: ConstrainedBox(
                            constraints: BoxConstraints.tight(Size.square(24)),
                            child: Center(
                              child: CustomText(
                                Constant.currencySymbol,
                                fontSize: context.font.large,
                                color: context.color.textDefaultColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          formaters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+')),
                          ],
                          keyboard: TextInputType.number,
                          validator: isPriceOptional()
                              ? null
                              : CustomTextFieldValidator.nullCheck,
                          hintText: "0",
                          hintTextStyle: TextStyle(
                            color: context.color.textDefaultColor.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: context.font.normal,
                          ),
                        ),
                  SizedBox(height: 10),
                  CustomText("phoneNumber".translate(context)),
                  SizedBox(height: 10),
                  CustomTextFormField(
                    controller: adPhoneNumberController,
                    action: TextInputAction.next,
                    formaters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    keyboard: TextInputType.phone,
                    validator: CustomTextFieldValidator.phoneNumber,
                    hintText: "phoneNumberAddHint".translate(context),
                    hintTextStyle: TextStyle(
                      color: context.color.textDefaultColor.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: context.font.normal,
                    ),
                  ),
                  SizedBox(height: 10),
                  CustomText("video".translate(context)),
                  SizedBox(height: 10),
                  videoListener(),
                  SizedBox(height: 15),
                  CustomText(
                    "${"adSlug".translate(context)}\t(${"englishOnlyLbl".translate(context)})",
                  ),
                  SizedBox(height: 10),
                  CustomTextFormField(
                    controller: adSlugController,
                    formaters: [SlugFormatter()],
                    validator: CustomTextFieldValidator.slug,
                    action: TextInputAction.next,
                    hintText: "adSlugHere".translate(context),
                    hintTextStyle: TextStyle(
                      color: context.color.textDefaultColor.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: context.font.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget videoListener() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (videoFile != null)
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: context.color.territoryColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.video_collection, size: 40),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      videoFile = null;
                    });
                    _saveDraft();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        else if (videoURL != "")
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: context.color.territoryColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.video_collection, size: 40),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      videoURL = "";
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _pickVideo,
            child: DottedBorder(
              color: context.color.textLightColor.withValues(alpha: 0.1),
              dashPattern: const [5, 5],
              strokeWidth: 1.5,
              radius: const Radius.circular(10),
              borderType: BorderType.RRect,
              child: Container(
                width: 100,
                height: 100,
                color: context.color.textLightColor.withValues(alpha: 0.05),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam,
                        color: context.color.territoryColor,
                        size: 30,
                      ),
                      const SizedBox(height: 5),
                      CustomText(
                        "recordVideo".translate(context),
                        fontSize: context.font.small,
                        color: context.color.territoryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickVideo() async {
    final instrKey = RecordingStandards.getInstructionsKey(widget.breadCrumbItems ?? []);
    debugPrint("Selected Recording Instruction Key: $instrKey");

    // Authenticity Protocol Checklist (Spec 2.3) - Premium WOW UI
    bool? proceed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return AuthenticityProtocolDialog(
          instrKey: instrKey,
          onAccept: () {},
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeInOutBack.transform(anim1.value),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );

    if (proceed != true) return;
    
    // Explicitly check for Camera and Microphone permissions before starting
    // This is required for some Android versions to prevent "camera failed" errors.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted == false || 
        statuses[Permission.microphone]!.isGranted == false) {
      if (mounted) {
        UiUtils.showBlurredDialoge(
          context,
          dialoge: BlurredDialogBox(
            title: "permissionDenied".translate(context),
            content: CustomText("cameraAndMicPermissionRequired".translate(context)),
            acceptButtonName: "settingsLbl".translate(context),
            onAccept: () async {
              await openAppSettings();
            },
          ),
        );
      }
      return;
    }

    try {
      final XFile? video = await PickImage.picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        setState(() {
          videoFile = File(video.path);
        });
        _saveDraft();
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showError(context, e);
      }
    }
  }

  Widget checkmarkPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: context.color.territoryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              text,
              fontSize: context.font.large,
              color: context.color.textDefaultColor,
            ),
          ),
        ],
      ),
    );
  }

  void _onBreadCrumbItemTap(int index) {
    int popTimes = (widget.breadCrumbItems!.length - 1) - index;
    int current = index;
    int length = widget.breadCrumbItems!.length;

    for (int i = length - 1; i >= current + 1; i--) {
      widget.breadCrumbItems!.removeAt(i);
    }

    for (int i = 0; i < popTimes; i++) {
      Navigator.pop(context);
    }
    setState(() {});
  }


  Widget titleImageListener() {
    return _pickTitleImage.listenChangesInUI((context, List<File>? files) {
      Widget currentWidget = Container();
      File? file = files?.isNotEmpty == true ? files![0] : null;

      if (titleImageURL.isNotEmpty) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(
              context,
              provider: NetworkImage(titleImageURL),
            );
          },
          child: Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(5),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: UiUtils.getImage(titleImageURL, fit: BoxFit.cover),
          ),
        );
      }

      if (file != null) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(context, provider: FileImage(file));
          },
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.all(5),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.file(file, fit: BoxFit.cover),
              ),
            ],
          ),
        );
      }

      return Wrap(
        children: [
          if (file == null && titleImageURL.isEmpty)
            DottedBorder(
              color: context.color.textLightColor,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: GestureDetector(
                onTap: () async {
                  if (await Permission.camera.request().isGranted) {
                    _pickTitleImage.pick(
                      pickMultiple: false,
                      context: context,
                      source: ImageSource.camera,
                    );
                    titleImageURL = "";
                    setState(() {});
                  } else {
                    if (mounted) {
                      UiUtils.showError(
                        context,
                        "cameraPermissionRequired".translate(context),
                      );
                    }
                  }
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: AlignmentDirectional.center,
                  height: 48,
                  child: CustomText(
                    "addMainPicture".translate(context),
                    color: context.color.textDefaultColor,
                    fontSize: context.font.normal,
                  ),
                ),
              ),
            ),
          Stack(
            children: [
              currentWidget,
              closeButton(context, () {
                _pickTitleImage.clearImage();
                titleImageURL = "";
                setState(() {});
                _saveDraft();
              }),
            ],
          ),
          if (file != null || titleImageURL.isNotEmpty)
            uploadPhotoCard(
              context,
              onTap: () async {
                if (await Permission.camera.request().isGranted) {
                  _pickTitleImage.pick(
                    pickMultiple: false,
                    context: context,
                    source: ImageSource.camera,
                  );
                  titleImageURL = "";
                  setState(() {});
                } else {
                  if (mounted) {
                    UiUtils.showError(
                      context,
                      "cameraPermissionRequired".translate(context),
                    );
                  }
                }
              },
            ),
        ],
      );
    });
  }

  Widget itemImagesListener() {
    return itemImagePicker.listenChangesInUI((context, files) {
      Widget current = Wrap(
        children: List.generate(mixedItemImageList.length, (index) {
          final image = mixedItemImageList[index];
          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  HelperUtils.unfocus();
                  if (image is String) {
                    UiUtils.showFullScreenImage(
                      context,
                      provider: NetworkImage(image),
                    );
                  } else {
                    UiUtils.showFullScreenImage(
                      context,
                      provider: FileImage(image),
                    );
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(5),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ImageAdapter(image: image),
                ),
              ),
              closeButton(context, () {
                if (image is String) {
                  final matchingIndex = item!.galleryImages!.indexWhere(
                    (galleryImage) => galleryImage.image == image,
                  );

                  if (matchingIndex != -1) {
                    deleteItemImageList.add(
                      item!.galleryImages![matchingIndex].id!,
                    );
                    setState(() {});
                  }
                }

                mixedItemImageList.removeAt(index);
                setState(() {});
                _saveDraft();
              }),
            ],
          );
        }),
      );

      return Wrap(
        runAlignment: WrapAlignment.start,
        children: [
          if (mixedItemImageList.isEmpty)
            DottedBorder(
              color: context.color.textLightColor,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: GestureDetector(
                onTap: () async {
                  if (await Permission.camera.request().isGranted) {
                    itemImagePicker.pick(
                      pickMultiple: false,
                      context: context,
                      imageLimit: 5,
                      maxLength: mixedItemImageList.length,
                      source: ImageSource.camera,
                    );
                  } else {
                    if (mounted) {
                      UiUtils.showError(
                        context,
                        "cameraPermissionRequired".translate(context),
                      );
                    }
                  }
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: AlignmentDirectional.center,
                  height: 48,
                  child: CustomText(
                    "addOtherPicture".translate(context),
                    color: context.color.textDefaultColor,
                    fontSize: context.font.normal,
                  ),
                ),
              ),
            ),
          current,
          if (mixedItemImageList.length < 5)
            if (mixedItemImageList.isNotEmpty)
              uploadPhotoCard(
                context,
                onTap: () async {
                  if (await Permission.camera.request().isGranted) {
                    itemImagePicker.pick(
                      pickMultiple: false,
                      context: context,
                      imageLimit: 5,
                      maxLength: mixedItemImageList.length,
                      source: ImageSource.camera,
                    );
                  } else {
                    if (mounted) {
                      UiUtils.showError(
                        context,
                        "cameraPermissionRequired".translate(context),
                      );
                    }
                  }
                },
              ),
        ],
      );
    });
  }

  Widget closeButton(BuildContext context, Function onTap) {
    return PositionedDirectional(
      top: 6,
      end: 6,
      child: GestureDetector(
        onTap: () {
          onTap.call();
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.color.primaryColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.close,
              size: 24,
              color: context.color.textDefaultColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget uploadPhotoCard(BuildContext context, {required Function onTap}) {
    return GestureDetector(
      onTap: () {
        onTap.call();
      },
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.all(5),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: DottedBorder(
          color: context.color.textColorDark.withValues(alpha: 0.5),
          borderType: BorderType.RRect,
          radius: const Radius.circular(10),
          child: Container(
            alignment: AlignmentDirectional.center,
            child: CustomText("uploadPhoto".translate(context)),
          ),
        ),
      ),
    );
  }

  Widget buildSalaryRange() {
    String? rangeChecker() {
      final min = int.tryParse(minSalaryController.text);
      final max = int.tryParse(maxSalaryController.text);

      if (min == null || max == null) return null;

      if (min < max) {
        return null;
      } else {
        return "invalidRange".translate(context);
      }
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: CustomTextFormField(
            controller: minSalaryController,
            action: TextInputAction.next,
            fixedPrefix: ConstrainedBox(
              constraints: BoxConstraints.tight(Size.square(24)),
              child: Center(
                child: CustomText(
                  Constant.currencySymbol,
                  fontSize: context.font.large,
                  color: context.color.textDefaultColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            formaters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+'))],
            validatorFunction: (value) => rangeChecker(),
            keyboard: TextInputType.number,
            hintText: "minLbl".translate(context),
            hintTextStyle: TextStyle(
              color: context.color.textDefaultColor.withValues(alpha: 0.5),
              fontSize: context.font.normal,
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: CustomTextFormField(
            controller: maxSalaryController,
            action: TextInputAction.next,
            fixedPrefix: ConstrainedBox(
              constraints: BoxConstraints.tight(Size.square(24)),
              child: Center(
                child: CustomText(
                  Constant.currencySymbol,
                  fontSize: context.font.large,
                  color: context.color.textDefaultColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            validatorFunction: (value) => rangeChecker(),
            formaters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+'))],
            keyboard: TextInputType.number,
            hintText: "maxLbl".translate(context),
            hintTextStyle: TextStyle(
              color: context.color.textDefaultColor.withValues(alpha: 0.5),
              fontSize: context.font.normal,
            ),
          ),
        ),
      ],
    );
  }

  void addDataToCloud(String key) {
    addCloudData(key, {
      "name": adTitleControllers[defaultLangCode]!.text,
      "slug": adSlugController.text,
      "description": adDescriptionControllers[defaultLangCode]!.text,
      if (widget.isEdit != true) "category_id": selectedCategoryList.last,
      if (widget.isEdit ?? false) "id": item?.id,
      "price": adPriceController.text,
      "contact": adPhoneNumberController.text,
      "video_link": adAdditionalDetailsController.text,
      if (widget.isEdit ?? false)
        "delete_item_image_id": deleteItemImageList.join(','),
      "all_category_ids": (widget.isEdit ?? false)
          ? item!.allCategoryIds
          : selectedCategoryList.join(','),
      if (isJobCategory()) "min_salary": minSalaryController.text,
      if (isJobCategory()) "max_salary": maxSalaryController.text,
    });
  }

  Future<void> _checkLostData() async {
    // Check if we already have recovered files from a previous static check
    if (PickImage.recoveredFiles != null && PickImage.recoveredFiles!.isNotEmpty) {
      _handleRecoveredFiles(PickImage.recoveredFiles!);
      PickImage.recoveredFiles = null; // Clear after use
      return;
    }

    final LostDataResponse response = await PickImage.picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    
    if (response.file != null) {
      File file = File(response.file!.path);
      _handleRecoveredFiles([file], type: response.type);
    } else if (response.files != null && response.files!.isNotEmpty) {
      List<File> files = response.files!.map((x) => File(x.path)).toList();
      _handleRecoveredFiles(files);
    }
  }

  Future<void> _handleRecoveredFiles(List<File> files, {RetrieveType? type}) async {
    for (var file in files) {
      File compressedFile = file;
      if (await file.length() > Constant.maxSizeInBytes) {
        compressedFile = await HelperUtils.compressImageFile(file);
      }

      if (type == RetrieveType.video) {
        setState(() {
          videoFile = compressedFile;
        });
      } else {
        if (_pickTitleImage.pickedFile == null && titleImageURL.isEmpty) {
          _pickTitleImage.injectFile(compressedFile);
        } else {
          mixedItemImageList.add(compressedFile);
        }
      }
    }
    setState(() {});
    _saveDraft();
  }

  void _saveDraft() {
    if (widget.isEdit == true) return;
    if (getCloudData('is_submitting') == true) return;

    Map draft = {
      "breadCrumbItems":
          widget.breadCrumbItems?.map((e) => e.toJson()).toList(),
      "title": adTitleControllers[defaultLangCode]?.text,
      "slug": adSlugController.text,
      "description": adDescriptionControllers[defaultLangCode]?.text,
      "price": adPriceController.text,
      "contact": adPhoneNumberController.text,
      "video_link": adAdditionalDetailsController.text,
      "min_salary": minSalaryController.text,
      "max_salary": maxSalaryController.text,
      "videoFile": videoFile?.path,
      "titleImage": _pickTitleImage.pickedFile?.path,
      "galleryImages": mixedItemImageList
          .where((e) => e is File)
          .map((e) => (e as File).path)
          .toList(),
    };
    HiveUtils.saveAddItemDraft(draft);
  }

  void _loadDraft() {
    try {
      final rawDraft = HiveUtils.getAddItemDraft();
      if (rawDraft == null) return;
      
      // Use dynamic Map to avoid casting issues from Hive
      Map draft = rawDraft;

      // We only load if the categories match or if we're resuming
      // Actually, it's safer to just load the text fields
      adSlugController.text = (draft['slug'] ?? "").toString();
      adPriceController.text = (draft['price'] ?? "").toString();
      adPhoneNumberController.text = (draft['contact'] ?? "").toString();
      adAdditionalDetailsController.text = (draft['video_link'] ?? "").toString();
      minSalaryController.text = (draft['min_salary'] ?? "").toString();
      maxSalaryController.text = (draft['max_salary'] ?? "").toString();

      if (adTitleControllers.containsKey(defaultLangCode)) {
        adTitleControllers[defaultLangCode]?.text = (draft['title'] ?? "").toString();
      }
      if (adDescriptionControllers.containsKey(defaultLangCode)) {
        adDescriptionControllers[defaultLangCode]?.text =
            (draft['description'] ?? "").toString();
      }

      if (draft['videoFile'] != null) {
        File vf = File(draft['videoFile'].toString());
        if (vf.existsSync()) videoFile = vf;
      }
      if (draft['titleImage'] != null) {
        File tf = File(draft['titleImage'].toString());
        if (tf.existsSync()) _pickTitleImage.injectFile(tf);
      }
      if (draft['galleryImages'] != null) {
        List paths = draft['galleryImages'] as List? ?? [];
        for (var path in paths) {
          String p = path.toString();
          File file = File(p);
          if (file.existsSync() && !mixedItemImageList.any((e) => e is File && e.path == p)) {
            mixedItemImageList.add(file);
          }
        }
      }
    } catch (e) {
      log("Error resuming draft: $e");
    }
  }
}
