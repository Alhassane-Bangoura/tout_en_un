-- SCRIPT D'INITIALISATION AB BUSINESS AI

-- 1. Table des Profils (Crédits et Infos)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  credits INTEGER DEFAULT 500,
  avatar_url TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Active RLS sur profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Les utilisateurs peuvent voir leur propre profil" 
ON public.profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Les utilisateurs peuvent modifier leur propre profil" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Trigger pour créer un profil à l'inscription (optionnel mais recommandé)
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, credits)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', 500);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Table des Activités Récentes
CREATE TABLE IF NOT EXISTS public.activities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  type TEXT NOT NULL, -- 'video', 'idea', 'marketing'
  result_summary TEXT, -- Court texte du résultat
  metadata JSONB, -- Données complètes (liens, scripts générés, etc.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Active RLS sur activities
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Les utilisateurs peuvent voir leurs propres activités" 
ON public.activities FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Les utilisateurs peuvent enregistrer leurs activités" 
ON public.activities FOR INSERT WITH CHECK (auth.uid() = user_id);
