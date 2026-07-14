import 'package:langlex_new_app/features/learning/models/learning_models.dart';

abstract class LearningState {
  const LearningState();
}

class LearningInitial extends LearningState {
  const LearningInitial();
}

class LearningLoading extends LearningState {
  const LearningLoading();
}

class LearningLoaded extends LearningState {
  const LearningLoaded(
    this.catalog, {
    this.setupSaving = false,
    this.setupError,
    this.setupSaved = false,
  });

  final LearningCatalog catalog;
  final bool setupSaving;
  final String? setupError;
  final bool setupSaved;
}

class LearningError extends LearningState {
  const LearningError(this.message);

  final String message;
}
