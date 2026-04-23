import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/data/models/profile_model.dart';
import '../../features/home/data/models/activity_model.dart';
import '../../features/tiktok_generator/data/models/tiktok_models.dart';
import '../../features/business_idea/data/models/business_idea_models.dart';
import '../../features/marketing_post/data/models/marketing_post_models.dart';
import 'supabase_client.dart';

class SupabaseService {
  final SupabaseClient _client = SupabaseClientInstance.client;

  /// Expose the client for direct Edge Function calls (used by chat widget)
  SupabaseClient getClient() => _client;

  // --- AUTHENTICATION ---
  
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    File? avatarFile,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    // Si une photo est fournie et que l'inscription a réussi
    if (avatarFile != null && response.user != null) {
      try {
        await uploadAvatar(avatarFile);
      } catch (e) {
        print('Erreur upload avatar lors de l\'inscription: $e');
        // On ne bloque pas l'inscription si seule la photo échoue
      }
    }
    
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider,
      redirectTo: 'io.supabase.flutter://callback',
    );
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutter://reset-callback',
    );
  }

  // --- STORAGE & PROFILE ---

  Future<String?> uploadAvatar(File file) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception("Upload annulé : L'utilisateur n'a pas encore de session active.");
    }

    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      // Note: Le bucket 'avatars' doit exister dans Supabase et avoir le RLS configuré
      await _client.storage.from('avatars').upload(filePath, file);

      final String publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);
      
      // Update profile with new avatar URL
      await _client.from('profiles').update({'avatar_url': publicUrl}).eq('id', user.id);
      
      return publicUrl;
    } on StorageException catch (e) {
      if (e.message.contains('Unauthorized')) {
        throw Exception("Permission refusée : Vous devez configurer les politiques RLS sur le bucket 'avatars' dans Supabase.");
      }
      throw Exception("Erreur stockage : ${e.message}");
    } catch (e) {
      throw Exception("Erreur upload photo: $e");
    }
  }

  Future<ProfileModel?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      Map<String, dynamic> profileData;

      if (data == null) {
        print('Profil manquant pour ${user.id}, création automatique...');
        final String? socialAvatar = user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];
        profileData = {
          'id': user.id,
          'full_name': user.userMetadata?['full_name'] ?? 'Utilisateur',
          'avatar_url': socialAvatar,
          'credits': 500,
        };
        await _client.from('profiles').insert(profileData);
      } else {
        profileData = Map<String, dynamic>.from(data as Map);
        
        // --- LOGIQUE SPÉCIALE PHASE DE TEST ---
        // Si les crédits sont bas, on les remet à 1000 pour ne pas bloquer les testeurs
        if ((profileData['credits'] as num? ?? 0) < 200) {
          print('Phase de Test : Recharge automatique (1000 crédits) pour ${user.id}');
          profileData['credits'] = 1000;
          try {
            await _client.from('profiles').update({'credits': 1000}).eq('id', user.id);
          } catch (e) {
            print('Erreur lors de la persistance de la recharge (test): $e');
            // On continue quand même avec les crédits en local pour débloquer l'utilisateur
          }
        }

        // Synchronisation du nom si manquant
        if (profileData['full_name'] == null || profileData['full_name'].toString().isEmpty) {
          final String? authName = user.userMetadata?['full_name'];
          if (authName != null) {
            profileData['full_name'] = authName;
            await _client.from('profiles').update({'full_name': authName}).eq('id', user.id);
          }
        }

        // Synchronisation de l'avatar si manquant (Social Login)
        if (profileData['avatar_url'] == null || profileData['avatar_url'].toString().isEmpty) {
          final String? socialAvatar = user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];
          if (socialAvatar != null) {
            profileData['avatar_url'] = socialAvatar;
            await _client.from('profiles').update({'avatar_url': socialAvatar}).eq('id', user.id);
          }
        }
      }

      return ProfileModel.fromJson(profileData);
    } catch (e) {
      print('Erreur getProfile: $e');
      return null;
    }
  }

  Future<void> updatePsychologicalProfile(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.from('profiles').update({
        'psychological_profile': data,
      }).eq('id', user.id);
    } catch (e) {
      print('Erreur updatePsychologicalProfile: $e');
    }
  }

  // Activités
  Future<List<ActivityModel>> getRecentActivities() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _client
          .from('activities')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(10);
      
      return (data as List).map((json) => ActivityModel.fromJson(json)).toList();
    } catch (e) {
      print('Erreur getActivities: $e');
      return [];
    }
  }

  Future<int> getTotalActivitiesCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    try {
      final data = await _client
          .from('activities')
          .select('id')
          .eq('user_id', user.id);
      
      return data.length;
    } catch (e) {
      print('Erreur getTotalActivitiesCount: $e');
      return 0;
    }
  }

  // Exemple d'action (diminution des crédits)
  Future<bool> consumeCredits(int amount) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final profile = await getProfile();
      if (profile == null || profile.credits < amount) return false;

      await _client
          .from('profiles')
          .update({'credits': profile.credits - amount})
          .eq('id', user.id);
      
      return true;
    } catch (e) {
      print('Erreur consumeCredits: $e');
      return false;
    }
  }

  // Activités : Enregistrement (Retourne l'objet créé)
  Future<ActivityModel?> saveActivity({
    required String title,
    required String type,
    String? resultSummary,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client.from('activities').insert({
        'user_id': user.id,
        'title': title,
        'type': type,
        'result_summary': resultSummary,
        'metadata': metadata,
      }).select().single();
      
      return ActivityModel.fromJson(data);
    } catch (e) {
      print('Erreur saveActivity: $e');
      return null;
    }
  }

  // Mise à jour des métadonnées (pour le chat par exemple)
  Future<void> updateActivityMetadata(String activityId, Map<String, dynamic> newMetadata) async {
    try {
      await _client.from('activities').update({
        'metadata': newMetadata,
      }).eq('id', activityId);
    } catch (e) {
      print('Erreur updateActivityMetadata: $e');
    }
  }

  // Génération de script TikTok via Groq (Edge Function)
  // Coût : 10 crédits
  Future<Map<String, dynamic>?> generateTiktokScript(TiktokRequestModel request) async {
    const int cost = 10;
    
    try {
      final profile = await getProfile();
      if (profile == null || profile.credits < cost) {
        throw Exception('Crédits insuffisants');
      }

      final response = await _client.functions.invoke(
        'smart-api',
        body: {
          'type': 'video',
          'product': request.product,
          'audience': request.targetAudience,
          'style': request.style,
        },
      );

      if (response.status != 200) {
        throw Exception('Erreur API: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      
      final script = TiktokScriptModel(
        hook: data['hook'] ?? '',
        cta: data['cta'] ?? '',
        body: (data['body'] as List? ?? []).map((item) => ScriptPart(
          timestamp: item['timestamp'] ?? '',
          content: item['content'] ?? '',
        )).toList(),
        alternativeHooks: List<String>.from(data['alternativeHooks'] ?? []),
        instructions: List<String>.from(data['instructions'] ?? []),
        viralScore: data['viralScore'] is int ? data['viralScore'] : 85,
        viralReason: data['viralReason'] ?? 'Bonne accroche visuelle.',
      );

      await consumeCredits(cost);
      final activity = await saveActivity(
        title: 'Script TikTok : ${request.product}',
        type: 'video',
        resultSummary: script.hook,
        metadata: script.toJson(),
      );
      
      return {
        'script': script,
        'activity': activity,
      };
    } catch (e) {
      print('Erreur generateTiktokScript: $e');
      rethrow;
    }
  }

  // Génération d'Idée de Business
  Future<Map<String, dynamic>?> generateBusinessIdea(BusinessIdeaRequestModel request) async {
    const int cost = 10;
    
    try {
      final profile = await getProfile();
      if (profile == null || profile.credits < cost) throw Exception('Crédits insuffisants');

      // Le prompt complexe et le bypass "video" ont été retirés.
      // Nous utilisons maintenant le type natif "idea" de l'Edge Function.
      // Elle gère elle-même le profil psychologique.
      final response = await _client.functions.invoke(
        'smart-api',
        body: {
          'type': 'idea',
          'budget': request.budget,
          'city': request.city,
          'niche': request.niche,
          'availableTime': request.availableTime,
          'skills': request.skills,
          'fears': request.fears,
          'businessIdea': request.businessIdea,
        },
      );

      if (response.status != 200) {
        throw Exception('Erreur API (${response.status}) : ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      final idea = BusinessIdeaModel.fromJson(data);

      await consumeCredits(cost);
      
      final fullMetadata = idea.toJson();
      fullMetadata['budget'] = request.budget;
      fullMetadata['city'] = request.city;
      fullMetadata['niche'] = request.niche;
      if (request.availableTime != null) fullMetadata['availableTime'] = request.availableTime;
      if (request.skills != null) fullMetadata['skills'] = request.skills;
      if (request.fears != null) fullMetadata['fears'] = request.fears;

      // Sauvegarder automatiquement dans le profil pour persistance
      await updatePsychologicalProfile({
        'budget': request.budget,
        'city': request.city,
        'niche': request.niche,
        'availableTime': request.availableTime,
        'skills': request.skills,
        'fears': request.fears,
      });

      final activity = await saveActivity(
        title: 'Idée Business : ${idea.title}',
        type: 'idea',
        resultSummary: idea.description,
        metadata: fullMetadata,
      );
      
      return {
        'idea': idea,
        'activity': activity,
      };
    } catch (e) {
      print('Erreur generateBusinessIdea: $e');
      rethrow;
    }
  }

  // Génération de Post Marketing
  Future<MarketingPostModel?> generateMarketingPost(MarketingPostRequestModel request) async {
    const int cost = 10;
    
    try {
      final profile = await getProfile();
      if (profile == null || profile.credits < cost) throw Exception('Crédits insuffisants');
      final response = await _client.functions.invoke(
        'smart-api',
        body: {
          'type': 'marketing',
          'product': request.product,
          'platform': request.platform,
          'tone': request.tone,
        },
      );

      if (response.status != 200) throw Exception('Erreur API: ${response.status}');

      final data = response.data as Map<String, dynamic>;
      final post = MarketingPostModel.fromJson(data);

      await consumeCredits(cost);
      await saveActivity(
        title: 'Post Marketing : ${request.product}',
        type: 'marketing',
        resultSummary: post.headline,
        metadata: post.toJson(),
      );
      
      return post;
    } catch (e) {
      print('Erreur generateMarketingPost: $e');
      rethrow;
    }
  }

  // --- INCUBATEUR (GEMINI MENTOR) ---

  Future<Map<String, dynamic>?> getActiveIncubatorProject() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('incubator_projects')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      return data;
    } catch (e) {
      print('Erreur getActiveIncubatorProject: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProjectById(String projectId) async {
    try {
      final data = await _client.from('incubator_projects').select().eq('id', projectId).single();
      return data;
    } catch (e) {
      print('Erreur getProjectById: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getIncubatorTasks(String projectId) async {
    try {
      final data = await _client
          .from('incubator_tasks')
          .select()
          .eq('project_id', projectId)
          .order('week_number', ascending: true)
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erreur getIncubatorTasks: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> startIncubation(BusinessIdeaRequestModel request) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    // 1. Appeler l'API Gemini pour créer la structure du projet
    final profile = await getProfile();
    if (profile == null || profile.credits < 50) throw Exception("Crédits insuffisants (50 requis pour lancer une incubation)");

    final response = await _client.functions.invoke(
      'mentor-api',
      body: {
        'type': 'generate_startup',
        'budget': request.budget,
        'city': request.city,
        'niche': request.niche,
        'availableTime': request.availableTime,
        'skills': request.skills,
        'fears': request.fears,
        'businessIdea': request.businessIdea,
      },
    );

    if (response.status != 200) {
      throw Exception('Erreur mentor-api: ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    
    // 2. Sauvegarder le Projet
    final projectInsert = await _client.from('incubator_projects').insert({
      'user_id': user.id,
      'title': data['title'] ?? 'Projet Startup',
      'description': data['description'] ?? '',
      'niche': request.niche,
      'psychological_profile': {
        'budget': request.budget,
        'fears': request.fears,
        'advice': data['psychologicalAdvice']
      },
    }).select().single();

    final projectId = projectInsert['id'];

    // 3. Sauvegarder les Tâches
    final List<dynamic> generatedTasks = data['tasks'] ?? [];
    List<Map<String, dynamic>> tasksToInsert = [];
    for (var t in generatedTasks) {
      tasksToInsert.add({
        'project_id': projectId,
        'user_id': user.id,
        'week_number': t['week_number'] ?? 1,
        'title': t['title'] ?? 'Nouvelle Tâche',
        'description': t['description'] ?? '',
        'status': 'pending'
      });
    }

    if (tasksToInsert.isNotEmpty) {
      await _client.from('incubator_tasks').insert(tasksToInsert);
    }

    await consumeCredits(50);
    return projectInsert;
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await _client.from('incubator_tasks').update({'status': status}).eq('id', taskId);
    } catch (e) {
      print('Erreur updateTaskStatus: $e');
    }
  }

  // --- SUBMIT WEEKLY REVIEW ---

  Future<Map<String, dynamic>?> submitWeeklyReview({
    required String projectId,
    required String userFeedback,
    required int currentWeek,
    required List<Map<String, dynamic>> previousTasks,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    // 1. Appeler l'API Mentor pour l'analyse
    final project = await _client.from('incubator_projects').select().eq('id', projectId).single();
    
    final response = await _client.functions.invoke(
      'mentor-api',
      body: {
        'type': 'weekly_review',
        'projectContext': project,
        'previousTasks': previousTasks,
        'userFeedback': userFeedback,
      },
    );

    if (response.status != 200) {
      throw Exception('Erreur mentor-api review: ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;

    // 2. Sauvegarder le rapport du mentor
    await _client.from('mentor_reports').insert({
      'project_id': projectId,
      'user_id': user.id,
      'week_number': currentWeek,
      'user_feedback': userFeedback,
      'mentor_response': data['mentor_response'],
    });

    // 3. Insérer les nouvelles tâches pour la semaine suivante
    final List<dynamic> newGeneratedTasks = data['new_tasks'] ?? [];
    List<Map<String, dynamic>> tasksToInsert = [];
    for (var t in newGeneratedTasks) {
      tasksToInsert.add({
        'project_id': projectId,
        'user_id': user.id,
        'week_number': currentWeek + 1,
        'title': t['title'] ?? 'Tâche Focus',
        'description': t['description'] ?? '',
        'status': 'pending'
      });
    }

    if (tasksToInsert.isNotEmpty) {
      await _client.from('incubator_tasks').insert(tasksToInsert);
    }

    return data;
  }

  Future<Map<String, dynamic>?> getLatestMentorReport(String projectId) async {
    try {
      final data = await _client
          .from('mentor_reports')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return data;
    } catch (e) {
      print('Erreur getLatestMentorReport: $e');
      return null;
    }
  }
}
