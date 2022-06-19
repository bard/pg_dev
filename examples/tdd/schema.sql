CREATE TABLE public.users (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name TEXT,
  PRIMARY KEY (id)
);
