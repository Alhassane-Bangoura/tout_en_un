-- SCRIPT D'EXTENSION: INCUBATEUR AB BUSINESS AI

-- 1. Table des Projets Incubés (La Startup de l'utilisateur)
CREATE TABLE IF NOT EXISTS public.incubator_projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  niche TEXT,
  psychological_profile JSONB, -- Stocke le budget, temps, peurs, compétences
  status TEXT DEFAULT 'active', -- 'active', 'completed', 'abandoned'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Active RLS
ALTER TABLE public.incubator_projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Voir ses propres projets" ON public.incubator_projects FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Créer ses propres projets" ON public.incubator_projects FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Modifier ses propres projets" ON public.incubator_projects FOR UPDATE USING (auth.uid() = user_id);

-- 2. Table des Tâches Focus (L'itération de travail)
CREATE TABLE IF NOT EXISTS public.incubator_tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID REFERENCES public.incubator_projects(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  week_number INTEGER DEFAULT 1,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'blocked'
  completion_proof TEXT, -- Un texte ou lien de preuve
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Active RLS
ALTER TABLE public.incubator_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Voir ses propres tâches" ON public.incubator_tasks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Créer ses propres tâches" ON public.incubator_tasks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Modifier ses propres tâches" ON public.incubator_tasks FOR UPDATE USING (auth.uid() = user_id);

-- 3. Table des Rapports de Mentorat (Bilan Hebdomadaire)
CREATE TABLE IF NOT EXISTS public.mentor_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID REFERENCES public.incubator_projects(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  week_number INTEGER NOT NULL,
  user_feedback TEXT NOT NULL, -- "J'ai réussi ça, mais j'ai bloqué sur ça"
  mentor_response TEXT, -- L'analyse générée par Gemini
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Active RLS
ALTER TABLE public.mentor_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Voir ses propres rapports" ON public.mentor_reports FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Créer ses propres rapports" ON public.mentor_reports FOR INSERT WITH CHECK (auth.uid() = user_id);
