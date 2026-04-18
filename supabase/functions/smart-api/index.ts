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

    if (type === 'idea') {
      const { budget, city, niche } = params;
      systemRole = "Tu es un consultant business expert. Ton rôle est de concevoir un concept de business viable, PAS un script de vidéo.";
      prompt = `CONÇOIS UNE IDÉE DE BUSINESS RENTABLE (PAS UN SCRIPT VIDÉO) pour :
Budget : ${budget}
Ville/Zone : ${city || 'Non spécifiée'}
Secteur/Niche : ${niche || 'Général'}

Le résultat doit être un plan d'affaires structuré au format JSON :
{
  "title": "Nom commercial accrocheur",
  "description": "Explique concrètement le concept du business et comment il gagne de l'argent",
  "steps": ["Étape 1 de mise en place", "Étape 2", "Étape 3"],
  "estimatedProfit": "Bénéfice net estimé par mois",
  "pros": ["Point fort du marché"],
  "cons": ["Difficulté technique ou logistique"]
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
