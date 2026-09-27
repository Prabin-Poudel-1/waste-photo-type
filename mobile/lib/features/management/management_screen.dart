import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../auth/auth_controller.dart';
import 'management_repository.dart';
import 'location_picker.dart';

class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Management')),
    body: ref.watch(authProvider).role != 'ADMIN'
        ? const Center(child: Text('Admin access required.'))
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final spots in [false, true])
                Card(
                  child: ListTile(
                    leading: Icon(
                      spots ? Icons.place_outlined : Icons.business_outlined,
                    ),
                    title: Text(spots ? 'Tourist Spots' : 'Departments'),
                    subtitle: Text(
                      spots
                          ? 'Manage supported destinations'
                          : 'Manage cleanup authorities',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ManagementList(spots: spots),
                      ),
                    ),
                  ),
                ),
            ],
          ),
  );
}

class ManagementList extends ConsumerStatefulWidget {
  final bool spots;
  const ManagementList({super.key, required this.spots});
  @override
  ConsumerState<ManagementList> createState() => _ManagementListState();
}

class _ManagementListState extends ConsumerState<ManagementList> {
  List<ManagedRecord>? records;
  String? error;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (ref.read(authProvider).role != 'ADMIN') {
      setState(() {
        loading = false;
        error = 'Admin access required.';
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await ref
          .read(managementRepositoryProvider)
          .list(widget.spots);
      if (mounted) {
        setState(() {
          records = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> edit([ManagedRecord? record]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ManagementForm(spots: widget.spots, record: record),
      ),
    );
    if (saved == true && mounted) {
      await load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.spots ? 'Tourist Spots' : 'Departments'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: ref.watch(authProvider).role == 'ADMIN'
        ? FloatingActionButton.extended(
            onPressed: () => edit(),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          )
        : null,
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!),
                TextButton(onPressed: load, child: const Text('Retry')),
              ],
            ),
          )
        : records!.isEmpty
        ? const Center(child: Text('No records yet. Tap Add to create one.'))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: records!.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = records![i];
              return ListTile(
                title: Text(item.name),
                subtitle: Text(item.active ? 'Active' : 'Inactive'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => edit(item),
              );
            },
          ),
  );
}

class ManagementForm extends ConsumerStatefulWidget {
  final bool spots;
  final ManagedRecord? record;
  const ManagementForm({super.key, required this.spots, this.record});
  @override
  ConsumerState<ManagementForm> createState() => _ManagementFormState();
}

class _ManagementFormState extends ConsumerState<ManagementForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, description, address, radius;
  late bool active;
  bool saving = false;
  String? error;
  LatLng? point;
  @override
  void initState() {
    super.initState();
    final r = widget.record;
    name = TextEditingController(text: r?.name ?? '');
    description = TextEditingController(text: r?.description ?? '');
    address = TextEditingController(text: r?.address ?? '');
    radius = TextEditingController(text: '${r?.radiusMeters ?? 700}');
    active = r?.active ?? true;
    if (r?.latitude != null && r?.longitude != null) {
      point = LatLng(r!.latitude!, r.longitude!);
    }
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    address.dispose();
    radius.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) {
      return;
    }
    if (widget.spots && point == null) {
      setState(() {
        error = 'Select the tourist spot on the map.';
      });
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (widget.record?.active == true && !active) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Deactivate this record?'),
            content: Text(
              widget.spots
                  ? 'Existing reports keep this destination. It will no longer be offered for new reports.'
                  : 'History and user links remain. New assignments are disabled, and linked department accounts lose operational access until reactivated.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Deactivate'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) {
          return;
        }
      }
      await ref.read(managementRepositoryProvider).save(
        widget.spots,
        widget.record?.id,
        {
          'name': name.text.trim(),
          'description': description.text.trim(),
          'active': active,
          if (widget.spots) ...{
            'latitude': double.parse(point!.latitude.toStringAsFixed(6)),
            'longitude': double.parse(point!.longitude.toStringAsFixed(6)),
            'radiusMeters': int.parse(radius.text.trim()),
            'address': address.text.trim(),
          },
        },
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.record == null ? 'Add' : 'Edit'} ${widget.spots ? 'Tourist Spot' : 'Department'}',
        ),
      ),
      body: ref.watch(authProvider).role != 'ADMIN'
          ? const Center(child: Text('Admin access required.'))
          : Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: name,
                    enabled: !saving,
                    maxLength: 150,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a name.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: description,
                    enabled: !saving,
                    maxLength: widget.spots ? 2000 : 1000,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                    ),
                  ),
                  if (widget.spots) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: address,
                      enabled: !saving,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Address (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              final selected = await Navigator.push<LatLng>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LocationPicker(initial: point),
                                ),
                              );
                              if (mounted && selected != null) {
                                setState(() {
                                  point = selected;
                                });
                              }
                            },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Select Location on Map'),
                    ),
                    if (point != null)
                      Text(
                        '${point!.latitude.toStringAsFixed(6)}, ${point!.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: radius,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Matching radius (metres)',
                        helperText: 'Application matching area, not an official boundary.',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        return n == null || n <= 0 || n > 2147483647
                            ? 'Enter a positive whole number.'
                            : null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    subtitle: const Text(
                      'Available for new reports or assignments',
                    ),
                    value: active,
                    onChanged: saving
                        ? null
                        : (value) => setState(() {
                            active = value;
                          }),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(saving ? 'Saving…' : 'Save'),
                  ),
                ],
              ),
            ),
    ),
  );
}
