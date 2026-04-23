import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY")

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { type, ...params } = await req.json()
    console.log(`[Mentor-API] Type de requête : ${type}`)

    if (!GROQ_API_KEY) {
      throw new Error("La clé d'API GROQ_API_KEY n'est pas configurée.")
    }

    let systemInstruction = "";
    let prompt = "";

    if (type === 'generate_startup') {
      const { budget, city, niche, availableTime, skills, fears, businessIdea } = params;
      
      systemInstruction = `Tu es un MENTOR BUSINESS SENIOR et STRATÈGE de classe mondiale. Ton obsession est la PRÉCISION et l'EXÉCUTION RÉELLE.
PROFIL DE L'INCUBÉ :
- Ville : ${city}
- Budget total : ${budget}
- Monnaie : GNF (Franc Guinéen) exclusivement.
- Compétences : ${skills}
- Peurs : ${fears}
- Temps disponible : ${availableTime}

TON APPROCHE :
1. Tu es DIRECT, PRAGMATIQUE et CHIRURGICAL.
2. Tu prends le BUDGET au sérieux. Si le budget est de 100 000 GNF, tu ne parles pas de "Marketing digital global", tu dis "Dépense 15 000 GNF pour imprimer 10 affiches et colle-les devant tel type de commerce à ${city}".
3. IMPORTANT : Calcule tous les coûts et profits en GNF exclusivement. INTERDICTION de citer le "FCFA", "CFA", "€", "$" ou "Dollar".
4. Chaque tâche doit être une action physique ou numérique concrète qu'on peut TERMINER en une journée.
5. Tu parles comme un humain expert qui a déjà réussi 10 business à ${city}.`;
      
      prompt = `CONÇOIS LE PLAN D'ACTION CHIRURGICAL POUR : "${businessIdea || niche}".

DÉVELOPPE UNE STRATÉGIE DE TERRAIN :
1. Liste précisément comment dépenser chaque billet de ton budget (${budget}).
2. Utilise les compétences (${skills}) pour sauter les étapes coûteuses.

IMPORTANT : Définis 4 missions (tasks) ultra-précises.
Une mission imprécise (ex: "Faire du marketing") est interdite. 
Une mission précise (ex: "Créer une Page Facebook 'Nom' et inviter 50 contacts de ${city}") est obligatoire.

Format JSON STRICT :
{
  "title": "Nom commercial",
  "description": "Ta stratégie de combat en 2 phrases.",
  "psychologicalAdvice": "Ton conseil de vétéran pour briser la peur (${fears}).",
  "tasks": [
    { "week_number": 1, "title": "Mission 1 : [Action terrain]", "description": "Détails techniques et étapes 1, 2, 3" },
    { "week_number": 2, "title": "...", "description": "..." },
    { "week_number": 3, "title": "...", "description": "..." },
    { "week_number": 4, "title": "...", "description": "..." }
  ]
}`;
    } else if (type === 'weekly_review') {
      const { projectContext, previousTasks, userFeedback } = params;
      const currentWeek = previousTasks.length > 0 ? previousTasks[0].week_number : 1;
      const isScaleUp = currentWeek >= 4;
      
      systemInstruction = `Tu es un MENTOR BUSINESS SENIOR de haut niveau. Tu analyses le compte rendu de ton entrepreneur. 
IMPORTANT : Utilise EXCLUSIVEMENT le GNF (Franc Guinéen) pour tout montant cité. BANNI les termes "FCFA", "CFA", "Euro", "Dollar".
${isScaleUp ? "ATTENTION : Le business a fini son incubation de base. Tu es maintenant en mode SCALE-UP PROFESSIONNEL. Tes conseils doivent viser l'excellence : optimisation des marges, automatisation, recrutement du premier employé, ou expansion géographique." : "Tu es en phase d'incubation initiale. Ton but est le lancement et la validation terrain."}`;
      
      prompt = `
CONTEXTE DU PROJET : ${JSON.stringify(projectContext)}
MISSIONS RÉCENTES (SEMAINE ${currentWeek}) : ${JSON.stringify(previousTasks)}
COMPTE RENDU DE L'ENTREPRENEUR : "${userFeedback}"

MISSION DU MENTOR :
1. Analyse les résultats avec honnêteté.
2. FÉLICITE chaleureusement l'entrepreneur pour ses efforts et MOTIVE-LE pour la suite.
3. ${isScaleUp ? "PROPOSE 3 missions de HAUT NIVEAU pour PROFESSIONNALISER le business (Scale-up) : expansion, automatisation ou délégation." : "Propose les focus de la SEMAINE ${currentWeek + 1}."}
4. Ton ton doit être celui d'un humain qui a bâti des empires : direct, inspirant et fier de son élève.

Format JSON STRICT exigé :
{
  "mentor_response": "Ta réponse stratégique humaine (max 350 caractères).",
  "new_tasks": [
    { "title": "...", "description": "..." }
  ]
}`;
    } else {
      return new Response(JSON.stringify({ error: "Type de requête mentor-api inconnu" }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Call Groq API (reliable Llama-3-70B)
    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          { role: "system", content: `${systemInstruction} Tu réponds TOUJOURS exclusivement en format JSON.` },
          { role: "user", content: prompt }
        ],
        temperature: 0.8,
        response_format: { type: "json_object" }
      })
    });

    const data = await response.json();

    if (data.error) {
      console.error("Groq API Error:", data.error);
      throw new Error(`Groq API Error: ${data.error.message}`);
    }

    const content = data.choices[0].message.content;

    return new Response(content, {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error("[Mentor-API] Error:", error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
