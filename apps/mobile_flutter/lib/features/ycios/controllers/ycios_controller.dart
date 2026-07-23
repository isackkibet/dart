import 'package:flutter/foundation.dart';
import '../repositories/ycios_repository.dart';

class YciosController extends ChangeNotifier {
  final YciosRepository repository;

  YciosController({required this.repository});

  bool loading = false;
  String? error;

  Future<void> createProject(String title, String description) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.createProject(title, description);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> archiveProject(String projectId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.archiveProject(projectId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> restoreProject(String projectId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.restoreProject(projectId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> duplicateProject(String projectId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      return await repository.duplicateProject(projectId);
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> askAgent({
    required String projectId,
    required String agentType,
    required String prompt,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.createAgentTask(
        projectId: projectId,
        agentType: agentType,
        prompt: prompt,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
