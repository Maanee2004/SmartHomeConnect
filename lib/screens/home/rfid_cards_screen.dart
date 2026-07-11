import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/rfid_card.dart';
import 'package:smart_home/models/rfid_door_config.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/services/rfid_cards_repository.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/load_error_view.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

class RfidCardsScreen extends StatefulWidget {
  const RfidCardsScreen({super.key});

  @override
  State<RfidCardsScreen> createState() => _RfidCardsScreenState();
}

class _RfidCardsScreenState extends State<RfidCardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<Device> _servos(List<Device> devices) =>
      devices.where((d) => d.normalizedType == 'SERVO').toList();

  List<Device> _readers(List<Device> devices) =>
      devices.where((d) => d.normalizedType == 'RFID').toList();

  Future<void> _linkReaderToDoor({
    required Device servo,
    required List<Device> readers,
    String? currentReaderId,
  }) async {
    String? selected = currentReaderId;
    if (readers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ajoute d’abord un lecteur RFID (type RFID) depuis le dashboard admin.',
          ),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Lecteur pour « ${servo.name} »',
          style: TextStyle(color: context.smartColors.textPrimary),
        ),
        content: StatefulBuilder(
          builder: (ctx, setSt) => DropdownMenu<String?>(
            label: Text(
              'Lecteur RFID',
              style: TextStyle(color: context.smartColors.textSecondary),
            ),
            initialSelection: selected,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: null, label: 'Aucun lecteur'),
              for (final r in readers)
                DropdownMenuEntry(
                  value: r.id,
                  label: '${r.name} (${r.piece ?? r.id})',
                ),
            ],
            onSelected: (v) => setSt(() => selected = v),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await RfidCardsRepository.instance.linkServoToReader(
        servoId: servo.id,
        readerId: selected,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecteur lié à la porte.')),
      );
    } on RfidCardFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _editBadge({
    RfidCard? existing,
    required List<Device> servos,
    required List<Device> readers,
    String? prefillUid,
    String? initialServoId,
    String? initialReaderId,
  }) async {
    final uidCtrl = TextEditingController(text: existing?.uid ?? prefillUid ?? '');
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    String? servoId = existing?.servoId ?? initialServoId;
    String? readerId = existing?.readerId ?? initialReaderId;
    var effect = existing?.effect ?? RfidBadgeEffect.toggle;

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: Text(
              existing == null ? 'Nouveau badge' : 'Modifier le badge',
              style: TextStyle(color: context.smartColors.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: uidCtrl,
                    enabled: existing == null,
                    style: TextStyle(color: context.smartColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'UID du badge',
                      hintText: 'ex. A1B2C3D4',
                      labelStyle:
                          TextStyle(color: context.smartColors.textSecondary),
                    ),
                  ),
                  if (existing == null && initialReaderId != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          final r = readers.cast<Device?>().firstWhere(
                                (x) => x?.id == initialReaderId,
                                orElse: () => null,
                              );
                          final last = r?.rfidBadgeUid;
                          if (last != null && last.isNotEmpty) {
                            setSt(() => uidCtrl.text = last);
                          }
                        },
                        icon: const Icon(Icons.sensors_rounded, size: 18),
                        label: const Text('Utiliser le dernier UID scanné'),
                      ),
                    ),
                  ] else if (existing == null && readers.length == 1) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          final last = readers.first.rfidBadgeUid;
                          if (last != null && last.isNotEmpty) {
                            uidCtrl.text = last;
                          }
                        },
                        icon: const Icon(Icons.sensors_rounded, size: 18),
                        label: const Text('Dernier UID scanné'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: labelCtrl,
                    style: TextStyle(color: context.smartColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Nom / propriétaire',
                      hintText: 'ex. Papa, Garage',
                      labelStyle:
                          TextStyle(color: context.smartColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownMenu<String?>(
                    label: Text(
                      'Porte (servomoteur)',
                      style: TextStyle(color: context.smartColors.textSecondary),
                    ),
                    initialSelection: servoId,
                    dropdownMenuEntries: [
                      if (servos.isEmpty)
                        const DropdownMenuEntry(
                          value: null,
                          label: 'Aucune porte configurée',
                        ),
                      for (final s in servos)
                        DropdownMenuEntry(
                          value: s.id,
                          label: '${s.name} — ${s.piece ?? s.id}',
                        ),
                    ],
                    onSelected: servos.isEmpty
                        ? null
                        : (v) => setSt(() => servoId = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownMenu<String?>(
                    label: Text(
                      'Lecteur RFID',
                      style: TextStyle(color: context.smartColors.textSecondary),
                    ),
                    initialSelection: readerId,
                    dropdownMenuEntries: [
                      if (initialReaderId == null)
                        const DropdownMenuEntry(
                          value: null,
                          label: 'Tout lecteur (non recommandé)',
                        ),
                      for (final r in readers)
                        DropdownMenuEntry(
                          value: r.id,
                          label: '${r.name} (${r.piece ?? r.id})',
                        ),
                    ],
                    onSelected: (v) => setSt(() => readerId = v ?? initialReaderId),
                  ),
                  const SizedBox(height: 8),
                  DropdownMenu<RfidBadgeEffect>(
                    label: Text(
                      'Effet',
                      style: TextStyle(color: context.smartColors.textSecondary),
                    ),
                    initialSelection: effect,
                    dropdownMenuEntries: [
                      for (final e in RfidBadgeEffect.values)
                        DropdownMenuEntry(value: e, label: e.label),
                    ],
                    onSelected: (v) {
                      if (v != null) setSt(() => effect = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(existing == null ? 'Ajouter' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      );
      if (ok != true || !mounted) return;

      if (existing == null) {
        await RfidCardsRepository.instance.addCard(
          uid: uidCtrl.text,
          label: labelCtrl.text,
          servoId: servoId,
          readerId: readerId,
          effect: effect,
        );
      } else {
        await RfidCardsRepository.instance.updateCard(
          cardId: existing.cardId,
          label: labelCtrl.text,
          servoId: servoId,
          readerId: readerId,
          effect: effect,
          clearServo: servoId == null,
          clearReader: readerId == null,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Badge ajouté.' : 'Badge mis à jour.'),
        ),
      );
    } on RfidCardFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      uidCtrl.dispose();
      labelCtrl.dispose();
    }
  }

  Future<void> _confirmDelete(RfidCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Supprimer « ${card.label} » ?',
          style: TextStyle(color: context.smartColors.textPrimary),
        ),
        content: Text(
          'UID ${card.uid} — ce badge ne pourra plus ouvrir la porte.',
          style: TextStyle(color: context.smartColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await RfidCardsRepository.instance.deleteCard(card.cardId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Badge « ${card.label} » supprimé.')),
      );
    } on RfidCardFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Widget _badgeTile(
    RfidCard card, {
    required List<Device> servos,
    required List<Device> readers,
    Device? doorServo,
  }) {
    final door = doorServo ??
        servos.cast<Device?>().firstWhere(
              (s) => s?.id == card.servoId,
              orElse: () => null,
            );
    final reader = readers.cast<Device?>().firstWhere(
          (r) => r?.id == card.readerId,
          orElse: () => null,
        );

    return Material(
      color: context.smartColors.card,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(
          backgroundColor: accentColor.withValues(alpha: 0.15),
          child: Icon(
            card.active ? Icons.nfc_rounded : Icons.nfc_outlined,
            color: card.active ? accentColor : context.smartColors.textSecondary,
          ),
        ),
        title: Text(
          card.label,
          style: TextStyle(
            color: context.smartColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'UID: ${card.uid}\n'
          '${door != null ? '🚪 ${door.name}' : 'Porte non assignée'}'
          '${reader != null ? ' · 📡 ${reader.name}' : ''}\n'
          '${card.effect.label}',
          style: TextStyle(
            color: context.smartColors.textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        onTap: () => _editBadge(
          existing: card,
          servos: servos,
          readers: readers,
        ),
        trailing: context.responsive.isTightWidth
            ? PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: context.smartColors.textSecondary),
                onSelected: (v) async {
                  if (v == 'toggle') {
                    try {
                      await RfidCardsRepository.instance.updateCard(
                        cardId: card.cardId,
                        active: !card.active,
                      );
                    } on RfidCardFailure catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }
                  } else if (v == 'delete') {
                    _confirmDelete(card);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(card.active ? 'Désactiver' : 'Activer'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer'),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: card.active,
                    activeThumbColor: accentColor,
                    onChanged: (v) async {
                      try {
                        await RfidCardsRepository.instance.updateCard(
                          cardId: card.cardId,
                          active: v,
                        );
                      } on RfidCardFailure catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: errorColor.withValues(alpha: 0.9),
                      size: 22,
                    ),
                    tooltip: 'Supprimer',
                    onPressed: () => _confirmDelete(card),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _readerCard({
    required RfidReaderConfig config,
    required List<Device> readers,
    required List<Device> servos,
  }) {
    final reader = config.reader;
    final door = config.linkedServo;
    final lastUid = reader.rfidBadgeUid;

    return Material(
      color: context.smartColors.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nfc_rounded, color: accentColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reader.name,
                    style: TextStyle(
                      color: context.smartColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${config.activeBadgeCount} badge(s)',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              reader.piece ?? reader.id,
              style: TextStyle(
                color: context.smartColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            _infoRow(
              icon: Icons.door_front_door_rounded,
              label: 'Porte liée',
              value: door != null
                  ? '${door.name} (${door.piece ?? door.id})'
                  : 'Aucune — lie depuis l’onglet Portes',
              highlight: door != null,
            ),
            if (lastUid != null && lastUid.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(
                icon: Icons.sensors_rounded,
                label: 'Dernier UID scanné',
                value: lastUid,
                highlight: true,
              ),
            ],
            const SizedBox(height: 12),
            context.responsive.buttonRow([
              if (lastUid != null && lastUid.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _editBadge(
                    servos: servos,
                    readers: readers,
                    prefillUid: lastUid,
                    initialServoId: door?.id,
                    initialReaderId: reader.id,
                  ),
                  icon: const Icon(Icons.sensors_rounded, size: 18),
                  label: const Text('Dernier scan'),
                ),
              FilledButton.icon(
                onPressed: () => _editBadge(
                  servos: servos,
                  readers: readers,
                  initialServoId: door?.id,
                  initialReaderId: reader.id,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajouter badge'),
              ),
            ]),
            if (config.badges.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Badges de ce lecteur',
                style: TextStyle(
                  color: context.smartColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...config.badges.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _badgeTile(
                    c,
                    servos: servos,
                    readers: readers,
                    doorServo: door,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Aucun badge pour ce lecteur. Scanne un badge puis appuie sur « Dernier scan » ou « Ajouter badge ».',
                style: TextStyle(
                  color: context.smartColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _doorCard({
    required RfidDoorConfig door,
    required List<Device> readers,
    required List<Device> servos,
  }) {
    final servo = door.servo;
    final linked = door.linkedReader;
    final lastUid = linked?.rfidBadgeUid;

    return Material(
      color: context.smartColors.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.door_front_door_rounded, color: accentColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    servo.name,
                    style: TextStyle(
                      color: context.smartColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  servo.isOn ? 'Ouverte' : 'Fermée',
                  style: TextStyle(
                    color: servo.isOn ? successColor : context.smartColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              servo.piece ?? '—',
              style: TextStyle(
                color: context.smartColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow(
              icon: Icons.sensors_rounded,
              label: 'Lecteur RFID',
              value: linked != null
                  ? '${linked.name} (${linked.id})'
                  : 'Non lié — configure ci-dessous',
              highlight: linked != null,
            ),
            if (lastUid != null && lastUid.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(
                icon: Icons.nfc_rounded,
                label: 'Dernier scan',
                value: lastUid,
                highlight: true,
              ),
            ],
            const SizedBox(height: 6),
            _infoRow(
              icon: Icons.badge_rounded,
              label: 'Badges autorisés',
              value:
                  '${door.activeBadgeCount} actif(s) / ${door.badges.length}',
              highlight: door.activeBadgeCount > 0,
            ),
            const SizedBox(height: 12),
            context.responsive.buttonRow([
              OutlinedButton.icon(
                onPressed: () => _linkReaderToDoor(
                  servo: servo,
                  readers: readers,
                  currentReaderId: servo.rfidCible,
                ),
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('Lier lecteur'),
              ),
              FilledButton.icon(
                onPressed: () => _editBadge(
                  servos: servos,
                  readers: readers,
                  prefillUid: lastUid,
                  initialServoId: servo.id,
                  initialReaderId: linked?.id,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Badge'),
              ),
            ]),
            if (door.badges.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Badges de cette porte',
                style: TextStyle(
                  color: context.smartColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...door.badges.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _badgeTile(
                    c,
                    servos: servos,
                    readers: readers,
                    doorServo: servo,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: highlight ? accentColor : context.smartColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.smartColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: context.smartColors.textPrimary,
                  fontSize: 13,
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = Firebase.apps.isNotEmpty;
    final repo = FirestoreHomeRepository.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Accès RFID',
          style: TextStyle(
            color: context.smartColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [ThemeToggleButton()],
        bottom: TabBar(
          controller: _tabs,
          labelColor: accentColor,
          unselectedLabelColor: context.smartColors.textSecondary,
          indicatorColor: accentColor,
          tabs: const [
            Tab(text: 'Lecteurs'),
            Tab(text: 'Portes'),
            Tab(text: 'Badges'),
          ],
        ),
      ),
      body: !firebaseReady
          ? Center(
              child: Text(
                'Firebase non initialisé.',
                style: TextStyle(color: context.smartColors.textSecondary),
              ),
            )
          : StreamBuilder<List<Device>>(
              stream: repo.watchDevices(),
              builder: (context, devSnap) {
                if (devSnap.hasError) {
                  return LoadErrorView(
                    message: '${devSnap.error}',
                    onRetry: () => setState(() {}),
                  );
                }
                final devices = devSnap.data ?? const <Device>[];
                final servos = _servos(devices);
                final readers = _readers(devices);

                return StreamBuilder<List<RfidCard>>(
                  stream: RfidCardsRepository.instance.watchCards(),
                  builder: (context, cardSnap) {
                    if (cardSnap.hasError) {
                      return LoadErrorView(
                        message: '${cardSnap.error}',
                        onRetry: () => setState(() {}),
                      );
                    }
                    if ((devSnap.connectionState == ConnectionState.waiting &&
                            !devSnap.hasData) ||
                        (cardSnap.connectionState == ConnectionState.waiting &&
                            !cardSnap.hasData)) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final cards = cardSnap.data ?? const <RfidCard>[];
                    final readerConfigs = RfidReaderConfig.build(
                      devices: devices,
                      cards: cards,
                    );
                    final doors = RfidDoorConfig.build(
                      devices: devices,
                      cards: cards,
                    );
                    final unassigned = RfidDoorConfig.unassignedBadges(cards);

                    return TabBarView(
                      controller: _tabs,
                      children: [
                        ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          children: [
                            _hintCard(
                              'Badges par lecteur',
                              'Chaque lecteur RFID peut avoir plusieurs badges autorisés. '
                              'Scanne un badge sur le lecteur, puis utilise « Dernier scan » pour l’enregistrer rapidement. '
                              'Tu peux changer ou réassigner un badge via l’édition.',
                            ),
                            if (readers.isEmpty)
                              _emptyBlock(
                                Icons.nfc_rounded,
                                'Aucun lecteur RFID',
                                'Ajoute un appareil de type RFID depuis le dashboard admin.',
                              )
                            else
                              ...readerConfigs.map(
                                (r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _readerCard(
                                    config: r,
                                    readers: readers,
                                    servos: servos,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          children: [
                            _hintCard(
                              'Coordination porte',
                              'Lie chaque porte (SERVO) à un lecteur RFID, puis ajoute les badges autorisés depuis l’onglet Lecteurs.',
                            ),
                            if (servos.isEmpty)
                              _emptyBlock(
                                Icons.door_sliding_rounded,
                                'Aucune porte (SERVO)',
                                'Ajoute un servomoteur depuis le dashboard admin.',
                              )
                            else
                              ...doors.map(
                                (d) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _doorCard(
                                    door: d,
                                    readers: readers,
                                    servos: servos,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: () => _editBadge(
                                  servos: servos,
                                  readers: readers,
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Nouveau badge'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (cards.isEmpty)
                              _emptyBlock(
                                Icons.nfc_rounded,
                                'Aucun badge',
                                'Crée des badges et assigne-les à une porte.',
                              )
                            else ...[
                              ...cards.map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _badgeTile(
                                    c,
                                    servos: servos,
                                    readers: readers,
                                  ),
                                ),
                              ),
                              if (unassigned.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Sans porte assignée (${unassigned.length})',
                                  style: TextStyle(
                                    color: warningColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _hintCard(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.smartColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: context.smartColors.textSecondary,
              height: 1.4,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBlock(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: context.smartColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: context.smartColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.smartColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
