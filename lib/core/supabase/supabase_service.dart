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

  // --- AUTHENTICATION ---
  
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
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

  // --- STORAGE & PROFILE ---

  Future<String?> uploadAvatar(File file) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await _client.storage.from('avatars').upload(filePath, file);

      final String publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);
      
      // Update profile with new avatar URL
      await _client.from('profiles').update({'avatar_url': publicUrl}).eq('id', user.id);
      
      return publicUrl;
    } catch (e) {
      print('Erreur uploadAvatar: $e');
      return null;
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
        profileData = {
          'id': user.id,
          'full_name': user.userMetadata?['full_name'] ?? 'Utilisateur',
          'credits': 500,
        };
        await _client.from('profiles').insert(profileData);
      } else {
        profileData = data as Map<String, dynamic>;
        
        // --- LOGIQUE SPÉCIALE PHASE DE TEST ---
        // Si les crédits sont < 500, on les remet à 500 pour ne pas bloquer les testeurs
        if ((profileData['credits'] as num? ?? 0) < 500) {
          print('Phase de Test : Remise à 500 crédits pour ${user.id}');
          profileData['credits'] = 500;
          await _client.from('profiles').update({'credits': 500}).eq('id', user.id);
        }

        // Synchronisation du nom si manquant
        if (profileData['full_name'] == null || profileData['full_name'].toString().isEmpty) {
          final String? authName = user.userMetadata?['full_name'];
          if (authName != null) {
            profileData['full_name'] = authName;
            await _client.from('profiles').update({'full_name': authName}).eq('id', user.id);
          }
        }
      }

      return ProfileModel.fromJson(profileData);
    } catch (e) {
      print('Erreur getProfile: $e');
      return null;
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

  // Activités : Enregistrement
  Future<void> saveActivity({
    required String title,
    required String type,
    String? resultSummary,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('activities').insert({
        'user_id': user.id,
        'title': title,
        'type': type,
        'result_summary': resultSummary,
        'metadata': metadata,
      });
    } catch (e) {
      print('Erreur saveActivity: $e');
    }
  }

  // Génération de script TikTok via Groq (Edge Function)
  // Coût : 10 crédits
  Future<TiktokScriptModel?> generateTiktokScript(TiktokRequestModel request) async {
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
      );

      await consumeCredits(cost);
      await saveActivity(
        title: 'Script TikTok : ${request.product}',
        type: 'video',
        resultSummary: script.hook,
        metadata: script.toJson(),
      );
      
      return script;
    } catch (e) {
      print('Erreur generateTiktokScript: $e');
      rethrow;
    }
  }

  // Génération d'Idée de Business
  Future<BusinessIdeaModel?> generateBusinessIdea(BusinessIdeaRequestModel request) async {
    const int cost = 10;
    
    try {
      final profile = await getProfile();
      if (profile == null || profile.credits < cost) throw Exception('Crédits insuffisants');

      print('Appel Edge Function smart-api avec type: idea');
      final response = await _client.functions.invoke(
        'smart-api',
        body: {
          'type': 'idea',
          'budget': request.budget,
          'city': request.city,
          'niche': request.niche,
        },
      );

      print('Réponse reçue (status: ${response.status})');

      if (response.status != 200) throw Exception('Erreur API: ${response.status}');

      final data = response.data as Map<String, dynamic>;
      final idea = BusinessIdeaModel.fromJson(data);

      await consumeCredits(cost);
      await saveActivity(
        title: 'Idée Business : ${idea.title}',
        type: 'idea',
        resultSummary: idea.description,
        metadata: idea.toJson(),
      );
      
      return idea;
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
}
