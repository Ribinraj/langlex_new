import 'package:langlex_new_app/features/learning/models/learning_models.dart';

abstract class LearningEvent {
  const LearningEvent();
}

class LoadLearningCatalogEvent extends LearningEvent {
  const LoadLearningCatalogEvent({this.forceRefresh = false});

  final bool forceRefresh;
}

class SaveLearningSetupEvent extends LearningEvent {
  const SaveLearningSetupEvent(this.setup);

  final LearningSetup setup;
}
