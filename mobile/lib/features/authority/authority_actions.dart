import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../analysis/models/detection_result.dart';
import '../auth/auth_controller.dart';
import '../capture/services/photo_service.dart';
import 'authority_repository.dart';

class AuthorityActions
    extends ConsumerStatefulWidget {
  final int id;
  final String status;
  final VoidCallback onSaved;

  const AuthorityActions({
    super.key,
    required this.id,
    required this.status,
    required this.onSaved,
  });

  @override
  ConsumerState<AuthorityActions> createState() {
    return _AuthorityActionsState();
  }
}

class _AuthorityActionsState
    extends ConsumerState<AuthorityActions> {
  final note = TextEditingController();

  WastePhoto? photo;
  bool busy = false;
  String? error;
  List<Map<String, dynamic>>? departments;
  int? departmentId;
  bool loadingDepartments = false;

  bool get admin {
    return ref.read(authProvider).role ==
        'ADMIN';
  }

  @override
  void initState() {
    super.initState();

    if (admin && widget.status == 'VERIFIED') {
      loadDepartments();
    }
  }

  Future<void> loadDepartments() async {
    setState(() {
      loadingDepartments = true;
      error = null;
    });

    try {
      final values = await ref
          .read(authorityRepositoryProvider)
          .departments();

      if (mounted) {
        setState(() {
          departments = values;
        });
      }
    } catch (caught) {
      if (mounted) {
        setState(() {
          error = caught.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loadingDepartments = false;
        });
      }
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  String? get next {
    return admin
        ? switch (widget.status) {
      'SUBMITTED' ||
      'AI_ANALYZED' ||
      'PENDING_VERIFICATION' =>
      'VERIFIED',
      'VERIFIED' => 'ASSIGNED',
      _ => null,
    }
        : switch (widget.status) {
      'ASSIGNED' => 'IN_PROGRESS',
      'IN_PROGRESS' => 'RESOLVED',
      _ => null,
    };
  }

  bool get canReject {
    return admin &&
        widget.status != 'RESOLVED' &&
        widget.status != 'REJECTED';
  }

  Future<void> pick(
      ImageSource source,
      ) async {
    setState(() {
      busy = true;
      error = null;
    });

    try {
      final result = await DevicePhotoService(
        ImagePicker(),
      ).pick(source);

      if (mounted && result != null) {
        setState(() {
          photo = result;
        });
      }
    } catch (caught) {
      if (mounted) {
        setState(() {
          error = caught.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> save(String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mark ${status.replaceAll('_', ' ')}?',
        ),
        content: const Text(
          'This change and note will be visible to the tourist.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true ||
        !mounted ||
        busy) {
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      await ref
          .read(authorityRepositoryProvider)
          .update(
        widget.id,
        status,
        note.text.trim(),
        photo,
        departmentId: departmentId,
      );

      if (mounted) {
        widget.onSaved();
      }
    } catch (caught) {
      if (mounted) {
        setState(() {
          error = caught.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (next == null && !canReject) {
      return const SizedBox.shrink();
    }

    return PopScope(
      canPop: !busy,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Authority actions',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                enabled: !busy,
                maxLength:
                next == 'ASSIGNED' ? 800 : 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText:
                  'Public update note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (next == 'ASSIGNED') ...[
                if (loadingDepartments)
                  const LinearProgressIndicator(),
                if (departments != null)
                  DropdownButtonFormField<int>(
                    initialValue: departmentId,
                    isExpanded: true,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Assign to department',
                    ),
                    items: departments!
                        .map(
                          (department) =>
                          DropdownMenuItem<int>(
                            value:
                            department['id']
                            as int,
                            child: Text(
                              department['name']
                              as String,
                            ),
                          ),
                    )
                        .toList(),
                    onChanged: busy
                        ? null
                        : (value) {
                      setState(() {
                        departmentId =
                            value;
                      });
                    },
                  ),
                if (!loadingDepartments &&
                    (departments == null ||
                        departments!.isEmpty))
                  TextButton(
                    onPressed: loadDepartments,
                    child: const Text(
                      'No departments available · Retry',
                    ),
                  ),
              ],
              if (next == 'RESOLVED') ...[
                const Text(
                  'Cleanup photo required',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => pick(
                        ImageSource.camera,
                      ),
                      icon: const Icon(
                        Icons.camera_alt,
                      ),
                      label:
                      const Text('Camera'),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => pick(
                        ImageSource.gallery,
                      ),
                      icon: const Icon(
                        Icons.photo_library,
                      ),
                      label:
                      const Text('Gallery'),
                    ),
                  ],
                ),
                if (photo != null)
                  Image.memory(
                    photo!.bytes,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
              ],
              if (error != null)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .error,
                    ),
                  ),
                ),
              if (busy)
                const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (next != null)
                    FilledButton(
                      onPressed: busy ||
                          (next ==
                              'ASSIGNED' &&
                              departmentId ==
                                  null) ||
                          (next ==
                              'RESOLVED' &&
                              photo == null)
                          ? null
                          : () => save(next!),
                      child: Text(
                        'Mark '
                            '${next!.replaceAll('_', ' ')}',
                      ),
                    ),
                  if (canReject)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () =>
                          save('REJECTED'),
                      child: const Text(
                        'Reject report',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}// Placeholder: paste the contents of mobile/lib/features/authority/authority_actions.dart from your app here.
