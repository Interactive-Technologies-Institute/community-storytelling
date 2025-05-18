-- User
INSERT INTO auth.users (
		instance_id,
		id,
		aud,
		role,
		email,
		encrypted_password,
		email_confirmed_at,
		recovery_sent_at,
		last_sign_in_at,
		raw_app_meta_data,
		raw_user_meta_data,
		created_at,
		updated_at,
		confirmation_token,
		email_change,
		email_change_token_new,
		recovery_token
	)
values (
		'00000000-0000-0000-0000-000000000000',
		uuid_generate_v4 (),
		'authenticated',
		'authenticated',
		'test@example.com',
		crypt ('Password123', gen_salt ('bf')),
		current_timestamp,
		current_timestamp,
		current_timestamp,
		'{"provider":"email","providers":["email"]}',
		'{"display_name": "Test User"}',
		current_timestamp,
		current_timestamp,
		'',
		'',
		'',
		''
	);
INSERT INTO auth.identities (
		id,
		user_id,
		provider_id,
		identity_data,
		provider,
		last_sign_in_at,
		created_at,
		updated_at
	) (
		select uuid_generate_v4 (),
			id,
			id,
			format('{"sub":"%s","email":"%s"}', id::text, email)::jsonb,
			'email',
			current_timestamp,
			current_timestamp,
			current_timestamp
		from auth.users
	);
-- How To
insert into public.howtos (
		user_id,
		title,
		description,
		image,
		tags,
		difficulty,
		duration,
		steps
	)
values (
		(
			select id
			from auth.users
			limit 1
		), 'How to make a sandwich', 'Learn how to make a delicious sandwich', 'placeholder.webp', array ['food', 'sandwich'], 'easy', 'short', array [
			'{ "step": 1, "title": "Get the ingredients", "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.","image": "placeholder.webp" }',
			'{ "step": 2, "title": "Prepare the ingredients", "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.","image": "placeholder.webp" }',
			'{ "step": 3, "title": "Assemble the sandwich", "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.","image": "placeholder.webp" }',
			'{ "step": 4, "title": "Enjoy your sandwich", "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.","image": "placeholder.webp" }']::jsonb []
	);
-- Event
insert into public.events (
		user_id,
		title,
		description,
		image,
		tags,
		date,
		location
	)
values (
		(
			select id
			from auth.users
			limit 1
		), 'Community BBQ', 'Join us for a community BBQ. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.', 'placeholder.webp', array ['community', 'bbq'], current_timestamp,
		'Community Park'
	);
-- Map Pin
insert into public.map_pins (user_id, lng, lat)
values (
		(
			select id
			from auth.users
			limit 1
		), 0, 0
	);