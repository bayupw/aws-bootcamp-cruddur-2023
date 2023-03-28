-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Andrew Brown','bayupwcruddur+andrewbrown@gmail.com' , 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko','bayupwcruddur+bayko@gmail.com' , 'bayko' ,'MOCK'),
  ('Londo Mollari', 'bayupwcruddur+londo@gmail.com','londo','MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )