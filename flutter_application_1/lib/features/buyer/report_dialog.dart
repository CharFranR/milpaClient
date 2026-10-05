import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/report_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

Future<bool> showReportDialog({
  required BuildContext context,
  required String targetType,
  required String targetId,
  ReportRepository? repository,
}) async {
  final bool? created = await showDialog<bool>(
    context: context,
    builder: (_) => _ReportDialog(
      targetType: targetType,
      targetId: targetId,
      repository: repository,
    ),
  );
  if (created == true && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Gracias, vamos a revisar el caso')),
      );
  }
  return created == true;
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({
    required this.targetType,
    required this.targetId,
    this.repository,
  });

  final String targetType;
  final String targetId;
  final ReportRepository? repository;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  late final ReportRepository _repository =
      widget.repository ??
      ReportRepository(apiClient: ApiClient(), tokenStore: TokenStore());
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String reason) {
    if (reason.length < 10) {
      return 'Contanos un poco más: el motivo necesita al menos 10 caracteres';
    }
    if (reason.length > 500) {
      return 'El motivo no puede superar los 500 caracteres';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_sending) return;
    final String reason = _controller.text.trim();
    final String? validation = _validate(reason);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _repository.report(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'No se pudo enviar el reporte';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? error = _error;
    return AlertDialog(
      title: const Text('Reportar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey<String>('report-reason'),
            controller: _controller,
            enabled: !_sending,
            maxLines: 4,
            maxLength: 500,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            decoration: const InputDecoration(hintText: 'Contanos qué pasó'),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(error, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: const Text('Volver'),
        ),
        FilledButton(
          onPressed: _sending ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.blackGreen),
          child: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Enviar reporte'),
        ),
      ],
    );
  }
}
