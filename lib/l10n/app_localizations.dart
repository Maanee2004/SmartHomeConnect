import 'package:flutter/material.dart';

/// Chaînes UI (fr / en / ar) — branchées sur [MaterialApp.locale].
class AppLocalizations {
  AppLocalizations(this.languageCode);

  final String languageCode;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String _t(String fr, String en, String ar) {
    switch (languageCode) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      default:
        return fr;
    }
  }

  // Navigation
  String get navHome => _t('Accueil', 'Home', 'الرئيسية');
  String get navRooms => _t('Pièces', 'Rooms', 'الغرف');
  String get navProfile => _t('Profil', 'Profile', 'الملف');
  String get navSettings => _t('Paramètres', 'Settings', 'الإعدادات');
  String get navHouses => _t('Maisons', 'Houses', 'المنازل');
  String get navUsers => _t('Utilisateurs', 'Users', 'المستخدمون');

  // Branding
  String get tagline =>
      _t('Maison connectée', 'Connected home', 'منزل متصل');

  // Profil
  String get userDefault => _t('Utilisateur', 'User', 'مستخدم');
  String get userIdLabel => _t('Identifiant', 'User ID', 'المعرف');
  String get sectionPersonalization =>
      _t('Personnalisation', 'Personalization', 'التخصيص');
  String get darkTheme => _t('Thème sombre', 'Dark theme', 'السمة الداكنة');
  String get themeDarkSubtitle =>
      _t('Bleu nuit', 'Night blue', 'أزرق ليلي');
  String get themeLightSubtitle =>
      _t('Mode clair', 'Light mode', 'الوضع الفاتح');
  String get language => _t('Langue', 'Language', 'اللغة');
  String get font => _t('Police', 'Font', 'الخط');
  String get fontSize => _t('Taille du texte', 'Text size', 'حجم النص');
  String get sectionDateTime =>
      _t('Date et heure (optionnel)', 'Date & time (optional)', 'التاريخ والوقت');
  String get showDateTime =>
      _t('Afficher date et heure', 'Show date and time', 'إظهار التاريخ والوقت');
  String get showDateTimeHint =>
      _t('Visible sur le profil', 'Shown on profile', 'يظهر في الملف');
  String get format24h => _t('Format 24 h', '24-hour format', 'تنسيق 24 ساعة');
  String get dateFormat => _t('Format de date', 'Date format', 'تنسيق التاريخ');
  String get memberHousePrefix =>
      _t('Maison de', 'House of', 'منزل');
  String get leaveHouse => _t('Quitter la maison', 'Leave house', 'مغادرة المنزل');
  String get logout => _t('Se déconnecter', 'Log out', 'تسجيل الخروج');
  String get leaveHouseTitle =>
      _t('Quitter la maison ?', 'Leave this house?', 'مغادرة المنزل؟');
  String get leaveHouseBody => _t(
        'Vous n’aurez plus accès aux appareils de cette maison.',
        'You will no longer access devices in this house.',
        'لن يعد بإمكانك الوصول إلى أجهزة هذا المنزل.',
      );
  String get cancel => _t('Annuler', 'Cancel', 'إلغاء');
  String get leave => _t('Quitter', 'Leave', 'مغادرة');
  String get leftHouseSnackbar => _t(
        'Vous avez quitté la maison.',
        'You left the house.',
        'لقد غادرت المنزل.',
      );

  String roleLabel(String? role) {
    if (role == 'admin') {
      return _t('Administrateur', 'Administrator', 'مسؤول');
    }
    if (role == 'owner') {
      return _t('Propriétaire', 'Owner', 'مالك');
    }
    return _t('Utilisateur', 'User', 'مستخدم');
  }

  String fontScaleLabel(String key) {
    switch (key) {
      case 'small':
        return _t('Petite', 'Small', 'صغير');
      case 'large':
        return _t('Grande', 'Large', 'كبير');
      case 'xlarge':
        return _t('Très grande', 'Extra large', 'كبير جداً');
      default:
        return _t('Normale', 'Normal', 'عادي');
    }
  }

  String get joinHouse =>
      _t('Rejoindre une maison', 'Join a house', 'انضم إلى منزل');

  // Paramètres
  String get settingsTitle => navSettings;
  String get sectionAppearance =>
      _t('Apparence', 'Appearance', 'المظهر');
  String get themeLanguageFont => _t(
        'Thème, langue et police',
        'Theme, language & font',
        'السمة واللغة والخط',
      );
  String get themeLanguageFontHint => _t(
        'Réglages dans l’onglet Profil',
        'Adjust in the Profile tab',
        'الإعدادات في تبويب الملف',
      );
  String get openProfileTabSnackbar => _t(
        'Ouvre l’onglet Profil en bas.',
        'Open the Profile tab at the bottom.',
        'افتح تبويب الملف في الأسفل.',
      );
  String get sectionNotifications =>
      _t('Notifications', 'Notifications', 'الإشعارات');
  String get sectionRemoteAccess =>
      _t('Accès distant', 'Remote access', 'الوصول عن بُعد');
  String get mobileWifiAccess => _t(
        'Accès mobile (Wi‑Fi)',
        'Mobile access (Wi‑Fi)',
        'الوصول عبر Wi‑Fi',
      );
  String get mobileWifiHint => _t(
        'Connexion au PC sur le même Wi‑Fi (QR ou lien direct)',
        'Connect to the PC on the same Wi‑Fi (QR or link)',
        'الاتصال بالحاسوب على نفس شبكة Wi‑Fi',
      );
  String get sectionGuides =>
      _t('Guides utilisateur', 'User guides', 'أدلة المستخدم');
  String get guideOwner => _t('Guide propriétaire', 'Owner guide', 'دليل المالك');
  String get guideGuest => _t('Guide invité', 'Guest guide', 'دليل الضيف');
  String get guideUser => _t('Guide utilisateur', 'User guide', 'دليل المستخدم');

  String get guideOwnerSubtitle => _t(
        'Pièces, appareils, invités, RFID — en autonomie',
        'Rooms, devices, guests, RFID — on your own',
        'الغرف والأجهزة والضيوف وRFID',
      );
  String get guideGuestSubtitle => _t(
        'Permissions et utilisation de l’app',
        'Permissions and how to use the app',
        'الصلاحيات واستخدام التطبيق',
      );
  String get sectionHouse => _t('Maison', 'House', 'المنزل');
  String get myGuests => _t('Mes invités', 'My guests', 'ضيوفي');
  String get myGuestsHint => _t(
        'Codes d’invitation et membres',
        'Invite codes and members',
        'رموز الدعوة والأعضاء',
      );
  String get joinHouseHint => _t(
        'Saisir un code invité à 5 chiffres',
        'Enter a 5-digit guest code',
        'أدخل رمز ضيف من 5 أرقام',
      );
  String get sectionSecurity => _t('Sécurité', 'Security', 'الأمان');
  String get rfidAccess => _t(
        'Accès RFID & portes',
        'RFID & door access',
        'RFID والأبواب',
      );
  String get rfidAccessHint => _t(
        'Badges, lecteurs et servomoteurs',
        'Badges, readers and servos',
        'البطاقات والقارئات والسيرفو',
      );

  // Thème (bouton rapide)
  String get themeTooltipLight =>
      _t('Mode clair', 'Light mode', 'الوضع الفاتح');
  String get themeTooltipDark =>
      _t('Mode sombre', 'Dark mode', 'الوضع الداكن');

  // Dashboard — titres & statut
  String get appTitle => _t('Smart Home', 'Smart Home', 'Smart Home');
  String get myHouse => _t('Ma maison', 'My home', 'منزلي');
  String get wholeHouse =>
      _t('Toute la maison', 'Whole home', 'كل المنزل');
  String get defaultRoomSalon => _t('Salon', 'Living room', 'الصالة');
  String get hello => _t('Bonjour', 'Hello', 'مرحباً');
  String get notConnected =>
      _t('Non connecté', 'Not connected', 'غير متصل');
  String get houseOnline =>
      _t('Maison en ligne', 'Home online', 'المنزل متصل');
  String get houseOffline =>
      _t('Maison hors ligne', 'Home offline', 'المنزل غير متصل');
  String get memberModeHint => _t(
        'Mode membre : allume/éteins les appareils et classe-les dans une pièce (icône déplacer). L’ajout d’appareils et le choix des broches sont réservés au propriétaire.',
        'Member mode: turn devices on/off and assign them to a room (move icon). Adding devices and choosing GPIO pins are for the owner.',
        'وضع العضو: تشغيل/إيقاف وتعيين الغرفة. إضافة الأجهزة واختيار الدبابيس للمالك.',
      );
  String get ownerHintAddDevices => _t(
        'Bouton + pour ajouter · icône déplacer sur une carte · Guide complet dans Paramètres → Guides utilisateur.',
        'Use + to add · move icon on a card · Full guide in Settings → User guides.',
        'زر + للإضافة · أيقونة النقل على البطاقة · الدليل الكامل في الإعدادات.',
      );
  String get connectToControl => _t(
        'Connecte-toi pour piloter ta maison.',
        'Sign in to control your home.',
        'سجّل الدخول للتحكم في منزلك.',
      );
  String get firebaseNotInitialized => _t(
        'Firebase n’est pas initialisé.',
        'Firebase is not initialized.',
        'Firebase غير مهيأ.',
      );
  String get firebaseConfigureHint => _t(
        'Configure le projet (flutterfire configure) puis relance l’app.',
        'Configure the project (flutterfire configure) then restart the app.',
        'اضبط المشروع (flutterfire configure) ثم أعد تشغيل التطبيق.',
      );
  String get noRoomsYet => _t(
        'Aucune pièce pour l’instant.',
        'No rooms yet.',
        'لا توجد غرف بعد.',
      );
  String get connectToAddRooms => _t(
        'Connecte-toi pour ajouter des pièces.',
        'Sign in to add rooms.',
        'سجّل الدخول لإضافة غرف.',
      );
  String get addRoomFromMenu => _t(
        'Ajoute une pièce depuis le menu ⋮',
        'Add a room from the ⋮ menu',
        'أضف غرفة من قائمة ⋮',
      );
  String get orLoadDemo => _t(
        ' ou charge les données de démo.',
        ' or load demo data.',
        ' أو حمّل بيانات تجريبية.',
      );
  String get demoDataAdded => _t(
        'Données de démo ajoutées.',
        'Demo data added.',
        'تمت إضافة البيانات التجريبية.',
      );
  String get createDemoData => _t(
        'Créer des données de démo (Firestore)',
        'Create demo data (Firestore)',
        'إنشاء بيانات تجريبية (Firestore)',
      );
  String get noDevicesInHouse => _t(
        'Aucun appareil dans la maison.',
        'No devices in the home.',
        'لا أجهزة في المنزل.',
      );
  String get noDevicesInRoom => _t(
        'Aucun appareil dans cette pièce.',
        'No devices in this room.',
        'لا أجهزة في هذه الغرفة.',
      );
  String get usePlusToAdd => _t(
        'Utilise le bouton + pour en ajouter un.',
        'Use the + button to add one.',
        'استخدم زر + للإضافة.',
      );

  // Dashboard — pièces
  String get showDevices =>
      _t('Afficher les appareils', 'Show devices', 'عرض الأجهزة');
  String get noRoomsAddFirst => _t(
        'Aucune pièce. Ajoute la première ci-dessous.',
        'No rooms. Add the first one below.',
        'لا غرف. أضف الأولى أدناه.',
      );
  String get renameRoomTooltip =>
      _t('Renommer la pièce', 'Rename room', 'إعادة تسمية الغرفة');
  String get deleteRoomTooltip =>
      _t('Supprimer la pièce', 'Delete room', 'حذف الغرفة');
  String get addRoom => _t('Ajouter une pièce', 'Add a room', 'إضافة غرفة');
  String get newRoomTitle =>
      _t('Nouvelle pièce', 'New room', 'غرفة جديدة');
  String get roomNameHint =>
      _t('Nom de la pièce', 'Room name', 'اسم الغرفة');
  String get add => _t('Ajouter', 'Add', 'إضافة');
  String get save => _t('Enregistrer', 'Save', 'حفظ');
  String get renameRoomTitle =>
      _t('Renommer la pièce', 'Rename room', 'إعادة تسمية الغرفة');
  String get newNameHint =>
      _t('Nouveau nom', 'New name', 'اسم جديد');
  String roomAdded(String name, String suffix) => _t(
        'Pièce « $name » ajoutée.$suffix',
        'Room « $name » added.$suffix',
        'تمت إضافة الغرفة « $name ».$suffix',
      );
  String roomRenamed(String name) => _t(
        'Pièce renommée en « $name ».',
        'Room renamed to « $name ».',
        'تمت إعادة تسمية الغرفة إلى « $name ».',
      );
  String deleteDeviceTitle(String name) => _t(
        'Supprimer « $name » ?',
        'Delete « $name »?',
        'حذف « $name »؟',
      );
  String get deleteDeviceBody => _t(
        'L’appareil sera retiré de Firestore.',
        'The device will be removed from Firestore.',
        'سيُزال الجهاز من Firestore.',
      );
  String deviceDeleted(String name) => _t(
        '« $name » supprimé.',
        '« $name » deleted.',
        'تم حذف « $name ».',
      );
  String deleteRoomTitle(String name) => _t(
        'Supprimer « $name » ?',
        'Delete « $name »?',
        'حذف « $name »؟',
      );
  String get deleteRoomBody => _t(
        'La pièce et tous ses appareils seront retirés de Firestore.',
        'The room and all its devices will be removed from Firestore.',
        'ستُزال الغرفة وجميع أجهزتها من Firestore.',
      );
  String roomDeleted(String name) => _t(
        'Pièce « $name » supprimée.',
        'Room « $name » deleted.',
        'تم حذف الغرفة « $name ».',
      );
  String failureMessage(Object e) =>
      _t('Échec: $e', 'Failed: $e', 'فشل: $e');

  // Dashboard — appareils
  String get pickRoomForDevice => _t(
        'Placer dans quelle pièce ?',
        'Place in which room?',
        'في أي غرفة؟',
      );
  String get gpioPinRequired => _t(
        'Broche GPIO (obligatoire)',
        'GPIO pin (required)',
        'دبوس GPIO (إلزامي)',
      );
  String get gpioPinOptional => _t(
        'Broche GPIO (optionnel)',
        'GPIO pin (optional)',
        'دبوس GPIO (اختياري)',
      );
  String gpioPinRange(int min, int max) => _t(
        'Broches $min–$max',
        'Pins $min–$max',
        'دبابيس $min–$max',
      );
  String get deviceAlreadyInRoom => _t(
        'L’appareil est déjà dans cette pièce.',
        'Device is already in this room.',
        'الجهاز موجود بالفعل في هذه الغرفة.',
      );
  String deviceMoved(String name, String label) => _t(
        '« $name » déplacé vers $label.',
        '« $name » moved to $label.',
        '« $name » نُقل إلى $label.',
      );
  String get editPinTitle =>
      _t('Modifier la broche', 'Edit pin', 'تعديل الدبوس');
  String pinAssigned(int pin, String name) => _t(
        'Broche $pin assignée à « $name ».',
        'Pin $pin assigned to « $name ».',
        'تم تعيين الدبوس $pin لـ « $name ».',
      );
  String get rfidReaderOptional => _t(
        'Lecteur RFID lié (optionnel)',
        'Linked RFID reader (optional)',
        'قارئ RFID مرتبط (اختياري)',
      );
  String get noReader => _t('Aucun lecteur', 'No reader', 'لا قارئ');
  String get servoPinTitle =>
      _t('Broche du servomoteur', 'Servo pin', 'دبوس السيرفو');
  String get servoAdded => _t('Servo ajouté', 'Servo added', 'تمت إضافة السيرفو');
  String get dhtPinTitle =>
      _t('Broche du capteur DHT', 'DHT sensor pin', 'دبوس مستشعر DHT');
  String get dhtPinSubtitle => _t(
        'Un doc : température et humidité dans valeur (ex. 24.5/60)',
        'One doc: temp and humidity in value (e.g. 24.5/60)',
        'مستند واحد: الحرارة والرطوبة في value',
      );
  String dhtAdded(int pin) => _t(
        'Capteur DHT ajouté (valeur temp./hum., broche $pin).',
        'DHT sensor added (temp/hum. value, pin $pin).',
        'تمت إضافة DHT (قيمة حرارة/رطوبة، دبوس $pin).',
      );
  String deviceAdded(String name, String pinNote, String suffix) => _t(
        '« $name » ajouté$pinNote.$suffix',
        '« $name » added$pinNote.$suffix',
        '« $name » أُضيف$pinNote.$suffix',
      );
  String get addDevice => _t('Ajouter un appareil', 'Add device', 'إضافة جهاز');
  String get addDeviceSheetTitle =>
      _t('Ajouter un appareil', 'Add device', 'إضافة جهاز');
  String get allHouseAddHint => _t(
        'Tu affiches « Toute la maison » : on te demandera la pièce pour chaque ajout.',
        'Showing « Whole home »: you’ll pick a room for each add.',
        '« كل المنزل » : ستختار الغرفة لكل إضافة.',
      );
  String get typesUppercaseHint => _t(
        'Types enregistrés en MAJUSCULES (Arduino CONFIG).',
        'Types stored in UPPERCASE (Arduino CONFIG).',
        'الأنواع بأحرف كبيرة (Arduino CONFIG).',
      );
  String get sensorsSection => _t('Capteurs', 'Sensors', 'المستشعرات');
  String get actuatorsSection =>
      _t('Actionneurs', 'Actuators', 'المشغّلات');
  String get customDevice => _t(
        'Ajouter un appareil personnalisé…',
        'Add custom device…',
        'إضافة جهاز مخصص…',
      );
  String get customDeviceSubtitle => _t(
        'Nom, type et pièce au choix',
        'Name, type and room of your choice',
        'الاسم والنوع والغرفة حسب اختيارك',
      );
  String get customDeviceTitle => _t(
        'Appareil personnalisé',
        'Custom device',
        'جهاز مخصص',
      );
  String get nameLabel => _t('Nom', 'Name', 'الاسم');
  String get nameExampleHint =>
      _t('ex. Lampe bureau', 'e.g. Desk lamp', 'مثال: مصباح مكتب');
  String get typeLabel => _t('Type', 'Type', 'النوع');
  String get roomLabel => _t('Pièce', 'Room', 'الغرفة');
  String get enterName => _t('Indique un nom.', 'Enter a name.', 'أدخل اسماً.');
  String get pickRoomTooltip =>
      _t('Choisir la pièce', 'Choose room', 'اختر الغرفة');
  String get logoutTooltip =>
      _t('Se déconnecter', 'Log out', 'تسجيل الخروج');

  // Stats panel
  String get dashboardStatsTitle =>
      _t('Tableau de bord', 'Dashboard', 'لوحة التحكم');
  String get statOn => _t('Allumés', 'On', 'مشغّل');
  String get statOnSubtitle =>
      _t('actionneurs ON', 'actuators ON', 'مشغّلات ON');
  String get statTotal => _t('Total', 'Total', 'المجموع');
  String statTotalSubtitle(int sensors, int actuators) => _t(
        '$sensors cap. · $actuators act.',
        '$sensors sens. · $actuators act.',
        '$sensors مست. · $actuators مش.',
      );
  String get statConsumption => _t('Conso', 'Power', 'استهلاك');
  String get statConsumptionSubtitle => _t(
        'estim. instant.',
        'instant est.',
        'تقدير لحظي',
      );
  String get loadEstimate500 => _t(
        'Charge estimée / 500 W',
        'Estimated load / 500 W',
        'حمل تقديري / 500 W',
      );

  // Device card
  String get offline => _t('Hors ligne', 'Offline', 'غير متصل');
  String get sensorMeta => _t('capteur', 'sensor', 'مستشعر');
  String get actuatorMeta => _t('actionneur', 'actuator', 'مشغّل');
  String get stateActive => _t('Actif', 'Active', 'نشط');
  String get stateOn => _t('Allumé', 'On', 'مشغّل');
  String get stateOff => _t('Éteint', 'Off', 'مطفأ');
  String get motion => _t('Mouvement', 'Motion', 'حركة');
  String get motionDetected =>
      _t('Détecté', 'Detected', 'مكتشف');
  String get motionNone => _t('Aucun', 'None', 'لا شيء');
  String get badgeUid => _t('UID badge', 'Badge UID', 'UID البطاقة');
  String get waiting => _t('En attente', 'Waiting', 'في الانتظار');
  String get distance => _t('Distance', 'Distance', 'المسافة');
  String get temperature => _t('Température', 'Temperature', 'الحرارة');
  String get humidity => _t('Humidité', 'Humidity', 'الرطوبة');
  String get measurement => _t('Mesure', 'Reading', 'القياس');
  String get doorOpen => _t('Ouverte', 'Open', 'مفتوحة');
  String get doorClosed => _t('Fermée', 'Closed', 'مغلقة');
  String get waitingDht =>
      _t('En attente DHT…', 'Waiting for DHT…', 'انتظار DHT…');
  String get changeRoom => _t('Changer pièce', 'Change room', 'تغيير الغرفة');
  String get delete => _t('Supprimer', 'Delete', 'حذف');
  String get changeRoomTooltip => _t(
        'Changer de pièce',
        'Change room',
        'تغيير الغرفة',
      );
  String get deleteDeviceTooltip => _t(
        'Supprimer l’appareil',
        'Delete device',
        'حذف الجهاز',
      );
  String pinBadge(int? pin, {required bool required}) {
    if (pin != null) {
      return _t('Broche $pin', 'Pin $pin', 'دبوس $pin');
    }
    return required
        ? _t('Broche req.', 'Pin req.', 'دبوس مط.')
        : _t('Broche —', 'Pin —', 'دبوس —');
  }
  String rfidTarget(String id) => _t(
        'RFID : $id',
        'RFID: $id',
        'RFID: $id',
      );

  // GPIO / broches
  String get pinChooseTitle =>
      _t('Choisir une broche', 'Choose a pin', 'اختر دبوساً');
  String get pinOptionalTitle =>
      _t('Broche (optionnel)', 'Pin (optional)', 'دبوس (اختياري)');
  String pinRangeUser(int min, int max) => _t(
        'Broches disponibles de $min à $max.',
        'Available pins from $min to $max.',
        'الدبابيس المتاحة من $min إلى $max.',
      );
  String pinRangeTechnical(int min, int max) => _t(
        'Broches $min–$max (Arduino / ESP32, CONFIG matériel).',
        'Pins $min–$max (Arduino / ESP32 hardware CONFIG).',
        'دبابيس $min–$max (Arduino / ESP32).',
      );
  String get pinNumberLabel =>
      _t('Numéro de broche', 'Pin number', 'رقم الدبوس');
  String pinHintExample(int example) => _t(
        'ex. $example',
        'e.g. $example',
        'مثال $example',
      );
  String get pinFreeLabel =>
      _t('Broches libres', 'Free pins', 'دبابيس حرة');
  String get pinOccupiedLabel =>
      _t('Broches déjà utilisées', 'Pins already in use', 'دبابيس مستخدمة');
  String pinOccupiedBy(int pin, String deviceName) => _t(
        'Broche $pin → $deviceName',
        'Pin $pin → $deviceName',
        'دبوس $pin → $deviceName',
      );
  String pinOccupiedMore(int count) => _t(
        '… et $count autre(s).',
        '… and $count more.',
        '… و $count أخرى.',
      );
  String get pinEnterValidNumber => _t(
        'Saisis un numéro valide.',
        'Enter a valid number.',
        'أدخل رقماً صالحاً.',
      );
  String get pinSkip => _t('Passer', 'Skip', 'تخطي');
  String get pinValidate => _t('Valider', 'Confirm', 'تأكيد');
  String pinReservedHint(String pins) => _t(
        'Réservées module ESP32 (UART/SPI) : $pins.',
        'Reserved on ESP32 module (UART/SPI): $pins.',
        'محجوزة على ESP32 (UART/SPI): $pins.',
      );
  String get pinReservedSectionTitle => _t(
        'Broches indisponibles (module ESP32)',
        'Unavailable pins (ESP32 module)',
        'دبابيس غير متاحة (ESP32)',
      );
  String pinReservedLine(int pin, String roleSuffix) => _t(
        'Broche $pin$roleSuffix',
        'Pin $pin$roleSuffix',
        'دبوس $pin$roleSuffix',
      );
  String pinReservedNotAllowed(int pin) => _t(
        'La broche $pin est réservée (TX, RX, MOSI, RST…). Choisis une broche libre.',
        'Pin $pin is reserved (TX, RX, MOSI, RST…). Pick a free pin.',
        'الدبوس $pin محجوز. اختر دبوساً حراً.',
      );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr', 'en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      true;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
