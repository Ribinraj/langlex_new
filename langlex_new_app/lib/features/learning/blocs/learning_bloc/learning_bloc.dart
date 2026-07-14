import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';

class LearningBloc extends Bloc<LearningEvent, LearningState> {
  LearningBloc(this._repository) : super(const LearningInitial()) {
    on<LoadLearningCatalogEvent>(_onLoadCatalog);
    on<SaveLearningSetupEvent>(_onSaveLearningSetup);
    on<RecordDailyProgressEvent>(_onRecordDailyProgress);
  }

  final LearningRepository _repository;

  Future<void> _onLoadCatalog(
    LoadLearningCatalogEvent event,
    Emitter<LearningState> emit,
  ) async {
    if (!event.forceRefresh && state is LearningLoaded) return;

    emit(const LearningLoading());
    try {
      final catalog = await _repository.fetchCatalog();
      emit(LearningLoaded(catalog));
    } on ApiException catch (error) {
      emit(LearningError(error.message));
    } catch (_) {
      emit(const LearningError('Could not load learning content.'));
    }
  }

  Future<void> _onSaveLearningSetup(
    SaveLearningSetupEvent event,
    Emitter<LearningState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LearningLoaded) return;

    emit(LearningLoaded(currentState.catalog, setupSaving: true));
    try {
      final setup = await _repository.saveLearningSetup(
        event.setup,
        catalog: currentState.catalog,
      );
      emit(
        LearningLoaded(
          currentState.catalog.copyWith(
            setup: setup,
            dailyGoal: currentState.catalog.dailyGoal.retarget(
              setup.dailyGoalMinutes,
            ),
          ),
          setupSaved: true,
        ),
      );
    } on ApiException catch (error) {
      emit(LearningLoaded(currentState.catalog, setupError: error.message));
    } catch (_) {
      emit(
        LearningLoaded(
          currentState.catalog,
          setupError: 'Could not save learning setup.',
        ),
      );
    }
  }

  Future<void> _onRecordDailyProgress(
    RecordDailyProgressEvent event,
    Emitter<LearningState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LearningLoaded) return;

    try {
      final dailyGoal = await _repository.recordDailyProgress(
        activityType: event.activityType,
        activityKey: event.activityKey,
        estimatedMinutes: event.estimatedMinutes,
      );
      emit(LearningLoaded(currentState.catalog.copyWith(dailyGoal: dailyGoal)));
    } catch (_) {
      // Daily progress should never interrupt a child while learning.
    }
  }
}
