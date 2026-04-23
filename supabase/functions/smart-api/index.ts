import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY")

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { type, ...params } = await req.json()
    console.log(`Type de requête reçu : ${type}`)

    let systemRole = "";
    let prompt = "";

    if (type === 'idea') {
      const { budget, city, niche, availableTime, skills, fears, businessIdea } = params;
      systemRole = `Tu es un MENTOR STRATÉGIQUE RÉALISTE. Ton but est d'aider quelqu'un qui a un budget (${budget}) et une niche (${niche}) mais qui manque de stratégie et d'expérience. 
Ville : ${city}
IMPORTANT : Utilise EXCLUSIVEMENT la monnaie GNF (Franc Guinéen) pour tous les calculs et estimations de profit.
INTERDICTION FORMELLE d'utiliser les termes : "FCFA", "CFA", "Franc CFA", "XOF", "XAF", "Euro", "Dollar". Si une monnaie étrangère est fournie en entrée, CONVERTIS-LA mentalement ou IGNORE-LA pour ne parler QUE en GNF.
Ton ton est celui d'un entrepreneur aguerri qui donne des conseils "terrain".`;

      prompt = `GÉNÈRE UNE STRATÉGIE DE DÉMARRAGE POUR : "${businessIdea || niche}".
Budget disponible : ${budget}
Profil : ${skills}
Plus grande peur : ${fears}

CONSIGNES DE MENTORAT :
1. Analyse comment maximiser les ${budget} à ${city}.
2. Ne propose pas d'idées génériques. Propose un angle d'attaque spécifique (ex: au lieu de "Restauration", propose "Livraison de petit déjeuner aux bureaux de Kaloum").
3. Adresse directement la peur (${fears}) dans ton explication.
4. Parle de "stratégie de croissance" et de "validation" au lieu de juste "étapes".

Format JSON :
{
  "title": "Nom du concept",
  "description": "Pourquoi c'est LA stratégie pour cette personne avec ce budget.",
  "steps": ["Phase de validation", "Phase d'encaissement", "Phase de système"],
  "estimatedProfit": "Profit mensuel net réaliste",
  "pros": ["Pourquoi le budget de ${budget} est un avantage"],
  "cons": ["Le défi principal de stratégie à surveiller"],
  "actionPlan30Days": [
    "Semaine 1 : [Action de terrain]",
    "Semaine 2 : [Lancement]",
    "Semaine 3 : [Optimisation]",
    "Semaine 4 : [Expansion]"
  ],
  "aiConclusion": "Ton conseil final de mentor sur pourquoi l'expérience viendra en pratiquant ce business précis."
}`;
    } else if (type === 'marketing') {
      const { product, platform, tone } = params;
      systemRole = "Tu es un copywriter expert en conversion pour les réseaux sociaux.";
      prompt = `Génère un post marketing impactant pour :
Produit : ${product}
Plateforme : ${platform || 'Facebook/WhatsApp'}
Ton : ${tone || 'Persuasif'}

Le résultat doit être au format JSON STRICT :
{
  "headline": "Titre accrocheur",
  "content": "Corps du message avec emojis",
  "cta": "Appel à l'action puissant",
  "hashtags": ["#tag1", "#tag2"]
}`;
    } else if (type === 'video') {
      const { product, audience, style } = params;
      systemRole = "Tu es un copywriter spécialisé dans les scripts TikTok à haute conversion.";
      prompt = `Génère un script de vidéo TikTok performant pour :
Produit : ${product}
Cible : ${audience || 'Grand public'}
Style : ${style || 'Dynamique'}

Le résultat doit être au format JSON STRICT :
{
  "hook": "Phrase d'accroche",
  "body": [
    { "timestamp": "0:05", "content": "Phrase 1" },
    { "timestamp": "0:15", "content": "Phrase 2" }
  ],
  "cta": "Appel à l'action",
  "instructions": ["Étape 1", "Étape 2"],
  "alternativeHooks": ["Hook 2", "Hook 3"]
}`;
    } else {
      return new Response(JSON.stringify({ error: "Type de requête inconnu ou manquant" }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          { role: "system", content: `${systemRole} Tu réponds toujours exclusivement en format JSON.` },
          { role: "user", content: prompt }
        ],
        temperature: 0.7,
        response_format: { type: "json_object" }
      })
    })

    const data = await response.json()
    
    if (data.error) {
      console.error("Groq API Error:", data.error)
      return new Response(JSON.stringify({ error: "Groq API Error", details: data.error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const content = data.choices[0].message.content

    return new Response(content, {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error("Error:", error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
