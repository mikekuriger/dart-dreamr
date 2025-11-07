// repository/life_event_repository.dart
import 'dart:async';
import 'package:dreamr/models/life_event.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:dreamr/data/life_event_dao.dart';
import 'package:flutter/material.dart';

class LifeEventRepository {
  final _dao = LifeEventDao();
  final _controller = StreamController<List<LifeEvent>>.broadcast();
  Stream<List<LifeEvent>> get stream => _controller.stream;

  /// Load events from local SQLite storage
  Future<List<LifeEvent>> loadLocal() async {
    try {
      debugPrint('Loading life events from local DB');
      final local = await _dao.getAll();
      debugPrint('Found ${local.length} life events in local DB');
      _controller.add(local);
      return local;
    } catch (e, stackTrace) {
      debugPrint('Error loading life events from local DB: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return empty list on error instead of crashing
      return [];
    }
  }

  /// Synchronize with server to get latest events
  /// Updates local DB and emits new local snapshot
  Future<void> syncFromServer() async {
    try {
      debugPrint('Syncing life events from server');
      final remote = await ApiService.fetchLifeEvents();
      debugPrint('Received ${remote.length} life events from server');
      
      if (remote.isNotEmpty) {
        await _dao.upsertMany(remote);
        debugPrint('Saved life events to local DB');
        
        final updated = await _dao.getAll();
        _controller.add(updated);
        debugPrint('Updated local event list with ${updated.length} events');
      }
    } catch (e, stackTrace) {
      debugPrint('Error syncing life events from server: $e');
      debugPrint('Stack trace: $stackTrace');
      // Do not rethrow to prevent UI errors
    }
  }

  /// Create a new life event
  Future<LifeEvent?> createLifeEvent({
    required DateTime occurredAt,
    required String title,
    String? details,
    List<String>? tags,
  }) async {
    try {
      debugPrint('Creating new life event');
      // Create via API
      final event = await ApiService.createLifeEvent(
        occurredAt: occurredAt,
        title: title,
        details: details,
        tags: tags,
      );
      
      if (event == null) {
        debugPrint('Failed to create life event: API returned null');
        return null;
      }
      
      debugPrint('Successfully created life event with ID: ${event.id}');
      
      // Save to local storage
      await _dao.upsert(event);
      debugPrint('Saved new life event to local DB');
      
      // Refresh local list
      final updated = await _dao.getAll();
      _controller.add(updated);
      
      return event;
    } catch (e, stackTrace) {
      debugPrint('Error creating life event: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return null instead of rethrowing to prevent errors in UI
      return null;
    }
  }

  /// Update an existing life event
  Future<LifeEvent?> updateLifeEvent({
    required int id,
    DateTime? occurredAt,
    String? title,
    String? details,
    List<String>? tags,
  }) async {
    try {
      debugPrint('Updating life event with ID: $id');
      // Update via API
      final updated = await ApiService.updateLifeEvent(
        id: id,
        occurredAt: occurredAt,
        title: title,
        details: details,
        tags: tags,
      );
      
      if (updated == null) {
        debugPrint('Failed to update life event: API returned null');
        return null;
      }
      
      debugPrint('Successfully updated life event');
      
      // Update local storage
      await _dao.upsert(updated);
      debugPrint('Updated life event in local DB');
      
      // Refresh local list
      final allEvents = await _dao.getAll();
      _controller.add(allEvents);
      
      return updated;
    } catch (e, stackTrace) {
      debugPrint('Error updating life event: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return null instead of rethrowing to prevent errors in UI
      return null;
    }
  }
  
  /// Delete a life event
  Future<bool> deleteLifeEvent(int id) async {
    try {
      debugPrint('Deleting life event with ID: $id');
      // Delete via API
      final success = await ApiService.deleteLifeEvent(id);
      
      if (!success) {
        debugPrint('Failed to delete life event from API');
        return false;
      }
      
      debugPrint('Successfully deleted life event from API');
      
      // Delete from local storage
      await _dao.delete(id);
      debugPrint('Deleted life event from local DB');
      
      // Refresh local list
      final updated = await _dao.getAll();
      _controller.add(updated);
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error deleting life event: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return false instead of rethrowing to prevent errors in UI
      return false;
    }
  }

  /// Close the stream controller when no longer needed
  void dispose() {
    _controller.close();
  }
}