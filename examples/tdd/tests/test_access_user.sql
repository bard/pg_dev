CREATE FUNCTION test_can_read_user_name()
  RETURNS SETOF TEXT
AS $$
  BEGIN
    INSERT INTO public.users (id, name)
    VALUES ('00000000-0000-0000-0000-000000000000', 'bob');

    RETURN NEXT row_eq(
      'SELECT name FROM public.users WHERE id = ''00000000-0000-0000-0000-000000000000''',
      ROW('bob'::text),
      'can read user name'
    );
  END;
$$ LANGUAGE plpgsql;
