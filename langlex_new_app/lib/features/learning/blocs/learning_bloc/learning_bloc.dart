import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';

class LearningBloc extends Bloc<LearningEvent, LearningState> {
  LearningBloc(this._repository) : super(const LearningInitial()) {
    on<LoadLearningCatalogEvent>(_onLoadCatalog);
    on<SaveLearningSetupEvent>(_onSaveLearningSetup);
  }

  final LearningRepository _repository;
  int _revision = 0;

  Future<void> _onLoadCatalog(
    LoadLearningCatalogEvent event,
    Emitter<LearningState> emit,
  ) async {
    if (!event.forceRefresh && state is LearningLoaded) return;

    final revision = ++_revision;
    emit(const LearningLoading());
    try {
      final catalog = await _repository.fetchCatalog();
      if (revision == _revision) emit(LearningLoaded(catalog));
    } on ApiException catch (error) {
      if (revision == _revision) emit(LearningError(error.message));
    } catch (_) {
      if (revision == _revision) {
        emit(const LearningError('Could not load learning content.'));
      }
    }
  }

  Future<void> _onSaveLearningSetup(
    SaveLearningSetupEvent event,
    Emitter<LearningState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LearningLoaded || currentState.setupSaving) return;
    final revision = ++_revision;
    bool saved = false;
    emit(LearningLoaded(currentState.catalog, setupSaving: true));
    try {
      await _repository.saveLearningSetup(
        event.setup,
        catalog: currentState.catalog,
      );
      saved = true;
      final catalog = await _repository.fetchCatalog();
      if (revision == _revision) {
        emit(LearningLoaded(catalog, setupSaved: true));
      }
    } on ApiException catch (error) {
      if (revision != _revision) return;
      if (saved) {
        emit(LearningError(error.message));
        return;
      }
      emit(LearningLoaded(currentState.catalog, setupError: error.message));
    } catch (_) {
      if (revision != _revision) return;
      if (saved) {
        emit(
          const LearningError(
            'Language saved. Please retry loading your content.',
          ),
        );
        return;
      }
      emit(
        LearningLoaded(
          currentState.catalog,
          setupError: 'Could not save learning setup.',
        ),
      );
    }
  }

}
