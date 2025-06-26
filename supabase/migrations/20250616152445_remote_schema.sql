SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

COMMENT ON SCHEMA "public" IS 'standard public schema';

CREATE EXTENSION IF NOT EXISTS "moddatetime" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";


CREATE TYPE "public"."feature" AS ENUM (
    'howtos',
    'events',
    'map',
    'academy',
    'stories'
);

ALTER TYPE "public"."feature" OWNER TO "postgres";


CREATE TYPE "public"."how_to_difficulty" AS ENUM (
    'easy',
    'medium',
    'hard'
);

ALTER TYPE "public"."how_to_difficulty" OWNER TO "postgres";


CREATE TYPE "public"."how_to_duration" AS ENUM (
    'short',
    'medium',
    'long'
);

ALTER TYPE "public"."how_to_duration" OWNER TO "postgres";


CREATE TYPE "public"."moderation_status" AS ENUM (
    'pending',
    'changes_requested',
    'approved',
    'rejected'
);

ALTER TYPE "public"."moderation_status" OWNER TO "postgres";


CREATE TYPE "public"."notification_type" AS ENUM (
    'howto_pending',
    'howto_changes_requested',
    'howto_approved',
    'howto_rejected',
    'event_pending',
    'event_changes_requested',
    'event_approved',
    'event_rejected',
    'map_pin_pending',
    'map_pin_changes_requested',
    'map_pin_approved',
    'map_pin_rejected'
);

ALTER TYPE "public"."notification_type" OWNER TO "postgres";


CREATE TYPE "public"."story_role" AS ENUM (
    'community',
    'introduction',
    'interview'
);

ALTER TYPE "public"."story_role" OWNER TO "postgres";


CREATE TYPE "public"."user_permission" AS ENUM (
    'user_roles.update',
    'user_types.update',
    'features.update',
    'branding.update',
    'howtos.create',
    'howtos.update',
    'howtos.delete',
    'howtos.moderate',
    'events.create',
    'events.update',
    'events.delete',
    'events.moderate',
    'story.create',
    'story.update',
    'story.delete',
    'story.moderate',
    'map.create',
    'map.update',
    'map.delete',
    'map.moderate'
);

ALTER TYPE "public"."user_permission" OWNER TO "postgres";


CREATE TYPE "public"."user_role" AS ENUM (
    'user',
    'moderator',
    'admin'
);

ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE TYPE "public"."user_type" AS (
	"slug" "text",
	"label" "text",
	"is_default" boolean
);

ALTER TYPE "public"."user_type" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."authorize"("requested_permission" "public"."user_permission") RETURNS boolean
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare bind_permissions int;
user_role public.user_role;
begin -- Fetch user role once and store it to reduce number of calls
select (auth.jwt()->>'user_role')::public.user_role into user_role;
select count(*) into bind_permissions
from public.role_permissions
where role_permissions.permission = requested_permission
	and role_permissions.role = user_role;
return bind_permissions > 0;
end;
$$;


ALTER FUNCTION "public"."authorize"("requested_permission" "public"."user_permission") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."custom_access_token_hook"("event" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
declare claims jsonb;
user_role public.user_role;
begin -- Check if the user is marked as admin in the profiles table
select role into user_role
from public.user_roles
where id = (event->>'user_id')::uuid;
claims := event->'claims';
if user_role is not null then -- Set the claim
claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
else claims := jsonb_set(claims, '{user_role}', 'null');
end if;
event := jsonb_set(event, '{claims}', claims);
return event;
end;
$$;


ALTER FUNCTION "public"."custom_access_token_hook"("event" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_event_interest_count"("event_id" bigint, "user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("count" bigint, "has_interest" boolean)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
select count(*) as interest_count,
	case
		when exists (
			select 1
			from public.events_interested
			where user_id = user_id
				and event_id = event_id
		) then true
		else false
	end as has_interest
from public.events_interested
where event_id = event_id;
$$;


ALTER FUNCTION "public"."get_event_interest_count"("event_id" bigint, "user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_howto_useful_count"("howto_id" bigint, "user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("count" bigint, "has_useful" boolean)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
select count(*) as count,
	case
		when exists (
			select 1
			from public.howtos_useful
			where user_id = user_id
				and howto_id = howto_id
		) then true
		else false
	end as has_useful
from public.howtos_useful
where howto_id = howto_id;
$$;


ALTER FUNCTION "public"."get_howto_useful_count"("howto_id" bigint, "user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_event_moderation_updates"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ begin
insert into public.events_moderation (event_id, user_id, status, comment)
values (
		new.id,
		new.user_id,
		'pending'::moderation_status,
		'Pending moderation'
	);
return new;
end;
$$;


ALTER FUNCTION "public"."handle_event_moderation_updates"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_events_moderation_notification"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare notification_type notification_type;
begin if new.status = 'pending' then notification_type := 'event_pending';
elsif new.status = 'changes_requested' then notification_type := 'event_changes_requested';
elsif new.status = 'approved' then notification_type := 'event_approved';
elsif new.status = 'rejected' then notification_type := 'event_rejected';
end if;
insert into public.notifications (user_id, type, data)
values (
		new.user_id,
		notification_type,
		jsonb_build_object('event_id', new.event_id)
	);
return new;
end;
$$;


ALTER FUNCTION "public"."handle_events_moderation_notification"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_howto_moderation_updates"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ begin
insert into public.howtos_moderation (howto_id, user_id, status, comment)
values (
		new.id,
		new.user_id,
		'pending'::moderation_status,
		'Pending moderation'
	);
return new;
end;
$$;


ALTER FUNCTION "public"."handle_howto_moderation_updates"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_howtos_moderation_notification"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare notification_type notification_type;
begin if new.status = 'pending' then notification_type := 'howto_pending';
elsif new.status = 'changes_requested' then notification_type := 'howto_changes_requested';
elsif new.status = 'approved' then notification_type := 'howto_approved';
elsif new.status = 'rejected' then notification_type := 'howto_rejected';
end if;
insert into public.notifications (user_id, type, data)
values (
		new.user_id,
		notification_type,
		jsonb_build_object('howto_id', new.howto_id)
	);
return new;
end;
$$;


ALTER FUNCTION "public"."handle_howtos_moderation_notification"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_map_pin_moderation_updates"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ begin
insert into public.map_pins_moderation (map_pin_id, user_id, status, comment)
values (
		new.id,
		new.user_id,
		'pending'::moderation_status,
		'Pending moderation'
	);
return new;
end;
$$;


ALTER FUNCTION "public"."handle_map_pin_moderation_updates"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_map_pins_moderation_notification"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare notification_type notification_type;
begin if new.status = 'pending' then notification_type := 'map_pin_pending';
elsif new.status = 'changes_requested' then notification_type := 'map_pin_changes_requested';
elsif new.status = 'approved' then notification_type := 'map_pin_approved';
elsif new.status = 'rejected' then notification_type := 'map_pin_rejected';
end if;
insert into public.notifications (user_id, type, data)
values (
		new.user_id,
		notification_type,
		jsonb_build_object('map_pin_id', new.map_pin_id)
	);
return new;
end;
$$;


ALTER FUNCTION "public"."handle_map_pins_moderation_notification"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ begin
insert into public.user_roles (id, role)
values (new.id, 'user');
insert into public.profiles (id, email, type, display_name)
values (
		new.id,
		new.email,
		(
			select slug
			from public.user_types
			where is_default = true
		),
		new.raw_user_meta_data->>'display_name'
	);
return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_story_moderation_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ begin
insert into public.story_moderation (story_id, user_id, status, comment)
values (
		new.id,
		new.user_id,
		'pending'::moderation_status,
		'Pending moderation'
	);
return new;
end;
$$;


ALTER FUNCTION "public"."handle_story_moderation_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_user_types"("types" "public"."user_type"[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
declare type user_type;
begin
delete from public.user_types
where true;
foreach type in array types loop
insert into public.user_types (slug, label, is_default)
values (type.slug, type.label, type.is_default);
end loop;
end;
$$;


ALTER FUNCTION "public"."update_user_types"("types" "public"."user_type"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verify_user_password"("password" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ begin return exists (
		select id
		from auth.users
		where id = auth.uid()
			and encrypted_password = crypt(password::text, auth.users.encrypted_password)
	);
end;
$$;


ALTER FUNCTION "public"."verify_user_password"("password" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."branding" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "name" "text" NOT NULL,
    "slogan" "text" NOT NULL,
    "logo" "text",
    "color_theme" "text" NOT NULL,
    "radius" double precision NOT NULL
);


ALTER TABLE "public"."branding" OWNER TO "postgres";


ALTER TABLE "public"."branding" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."branding_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."events" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "image" "text" NOT NULL,
    "tags" "text"[] NOT NULL,
    "date" timestamp with time zone NOT NULL,
    "location" "text" NOT NULL,
    "fts" "tsvector" GENERATED ALWAYS AS ("to_tsvector"('"simple"'::"regconfig", (("title" || ' '::"text") || "description"))) STORED
);


ALTER TABLE "public"."events" OWNER TO "postgres";


ALTER TABLE "public"."events" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."events_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."events_interested" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "user_id" "uuid" NOT NULL,
    "event_id" bigint NOT NULL
);


ALTER TABLE "public"."events_interested" OWNER TO "postgres";


ALTER TABLE "public"."events_interested" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."events_interested_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."events_moderation" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "event_id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "status" "public"."moderation_status" NOT NULL,
    "comment" "text" NOT NULL
);


ALTER TABLE "public"."events_moderation" OWNER TO "postgres";


ALTER TABLE "public"."events_moderation" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."events_moderation_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE OR REPLACE VIEW "public"."events_tags" WITH ("security_invoker"='on') AS
 SELECT "unnest"("events"."tags") AS "tag",
    "count"(*) AS "count"
   FROM "public"."events"
  GROUP BY ("unnest"("events"."tags"));


ALTER TABLE "public"."events_tags" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."latest_events_moderation" WITH ("security_invoker"='on') AS
 SELECT DISTINCT ON ("events_moderation"."event_id") "events_moderation"."id",
    "events_moderation"."inserted_at",
    "events_moderation"."event_id",
    "events_moderation"."user_id",
    "events_moderation"."status",
    "events_moderation"."comment"
   FROM "public"."events_moderation"
  ORDER BY "events_moderation"."event_id", "events_moderation"."inserted_at" DESC;


ALTER TABLE "public"."latest_events_moderation" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."events_view" WITH ("security_invoker"='on') AS
 SELECT "e"."id",
    "e"."inserted_at",
    "e"."updated_at",
    "e"."user_id",
    "e"."title",
    "e"."description",
    "e"."image",
    "e"."tags",
    "e"."date",
    "e"."location",
    "e"."fts",
    "m"."status" AS "moderation_status"
   FROM ("public"."events" "e"
     LEFT JOIN "public"."latest_events_moderation" "m" ON (("e"."id" = "m"."event_id")));


ALTER TABLE "public"."events_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feature_flags" (
    "id" "public"."feature" NOT NULL,
    "enabled" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."feature_flags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."howtos" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "image" "text" NOT NULL,
    "tags" "text"[] NOT NULL,
    "difficulty" "public"."how_to_difficulty" NOT NULL,
    "duration" "public"."how_to_duration" NOT NULL,
    "steps" "jsonb"[] NOT NULL,
    "fts" "tsvector" GENERATED ALWAYS AS ("to_tsvector"('"simple"'::"regconfig", (("title" || ' '::"text") || "description"))) STORED
);


ALTER TABLE "public"."howtos" OWNER TO "postgres";


ALTER TABLE "public"."howtos" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."howtos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."howtos_moderation" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "howto_id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "status" "public"."moderation_status" NOT NULL,
    "comment" "text" NOT NULL
);


ALTER TABLE "public"."howtos_moderation" OWNER TO "postgres";


ALTER TABLE "public"."howtos_moderation" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."howtos_moderation_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE OR REPLACE VIEW "public"."howtos_tags" WITH ("security_invoker"='on') AS
 SELECT "unnest"("howtos"."tags") AS "tag",
    "count"(*) AS "count"
   FROM "public"."howtos"
  GROUP BY ("unnest"("howtos"."tags"));


ALTER TABLE "public"."howtos_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."howtos_useful" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "user_id" "uuid" NOT NULL,
    "howto_id" bigint NOT NULL
);


ALTER TABLE "public"."howtos_useful" OWNER TO "postgres";


ALTER TABLE "public"."howtos_useful" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."howtos_useful_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE OR REPLACE VIEW "public"."latest_howtos_moderation" WITH ("security_invoker"='on') AS
 SELECT DISTINCT ON ("howtos_moderation"."howto_id") "howtos_moderation"."id",
    "howtos_moderation"."inserted_at",
    "howtos_moderation"."howto_id",
    "howtos_moderation"."user_id",
    "howtos_moderation"."status",
    "howtos_moderation"."comment"
   FROM "public"."howtos_moderation"
  ORDER BY "howtos_moderation"."howto_id", "howtos_moderation"."inserted_at" DESC;


ALTER TABLE "public"."latest_howtos_moderation" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."howtos_view" WITH ("security_invoker"='on') AS
 SELECT "h"."id",
    "h"."inserted_at",
    "h"."updated_at",
    "h"."user_id",
    "h"."title",
    "h"."description",
    "h"."image",
    "h"."tags",
    "h"."difficulty",
    "h"."duration",
    "h"."steps",
    "h"."fts",
    "m"."status" AS "moderation_status"
   FROM ("public"."howtos" "h"
     JOIN "public"."latest_howtos_moderation" "m" ON (("h"."id" = "m"."howto_id")));


ALTER TABLE "public"."howtos_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."map_pins_moderation" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "map_pin_id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "status" "public"."moderation_status" NOT NULL,
    "comment" "text" NOT NULL
);


ALTER TABLE "public"."map_pins_moderation" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."latest_map_pins_moderation" WITH ("security_invoker"='on') AS
 SELECT DISTINCT ON ("map_pins_moderation"."map_pin_id") "map_pins_moderation"."id",
    "map_pins_moderation"."inserted_at",
    "map_pins_moderation"."map_pin_id",
    "map_pins_moderation"."user_id",
    "map_pins_moderation"."status",
    "map_pins_moderation"."comment"
   FROM "public"."map_pins_moderation"
  ORDER BY "map_pins_moderation"."map_pin_id", "map_pins_moderation"."inserted_at" DESC;


ALTER TABLE "public"."latest_map_pins_moderation" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."map_pins" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "lng" double precision NOT NULL,
    "lat" double precision NOT NULL,
    "user_id" "uuid" NOT NULL,
    "story_id" bigint NOT NULL,
    "year" bigint
);


ALTER TABLE "public"."map_pins" OWNER TO "postgres";


ALTER TABLE "public"."map_pins" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."map_pins_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE "public"."map_pins_moderation" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."map_pins_moderation_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE OR REPLACE VIEW "public"."map_pins_view" WITH ("security_invoker"='on') AS
 SELECT "mp"."id",
    "mp"."inserted_at",
    "mp"."updated_at",
    "mp"."lng",
    "mp"."lat",
    "mp"."user_id",
    "m"."status" AS "moderation_status"
   FROM ("public"."map_pins" "mp"
     JOIN "public"."latest_map_pins_moderation" "m" ON (("mp"."id" = "m"."map_pin_id")));


ALTER TABLE "public"."map_pins_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "public"."notification_type" NOT NULL,
    "data" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "read" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


ALTER TABLE "public"."notifications" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."notifications_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "email" "text" NOT NULL,
    "type" "text" NOT NULL,
    "display_name" "text" NOT NULL,
    "description" "text",
    "avatar" "text"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "id" "uuid" NOT NULL,
    "role" "public"."user_role" NOT NULL
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."profiles_view" WITH ("security_invoker"='on') AS
 SELECT "p"."id",
    "p"."inserted_at",
    "p"."updated_at",
    "p"."email",
    "p"."type",
    "p"."display_name",
    "p"."description",
    "p"."avatar",
    "roles"."role"
   FROM ("public"."profiles" "p"
     LEFT JOIN "public"."user_roles" "roles" ON (("p"."id" = "roles"."id")));


ALTER TABLE "public"."profiles_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."role_permissions" (
    "id" bigint NOT NULL,
    "role" "public"."user_role" NOT NULL,
    "permission" "public"."user_permission" NOT NULL
);


ALTER TABLE "public"."role_permissions" OWNER TO "postgres";


ALTER TABLE "public"."role_permissions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."role_permissions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."story" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "storyteller" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "tags" "text"[] NOT NULL,
    "role" "public"."story_role" NOT NULL,
    "recording_link" "text" NOT NULL,
    "transcription" "text",
    "image" "text"[] NOT NULL,
    "template" "text",
    "pub_story_text" "text"[],
    "pub_quotes" "text"[],
    "pub_selected_images" "text"[],
    "insights_gpt" "text",
    "fts" "tsvector" GENERATED ALWAYS AS ("to_tsvector"('"simple"'::"regconfig", ("storyteller" || ' '::"text"))) STORED
);


ALTER TABLE "public"."story" OWNER TO "postgres";


ALTER TABLE "public"."story" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."story_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."story_moderation" (
    "id" bigint NOT NULL,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "story_id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "status" "public"."moderation_status" NOT NULL,
    "comment" "text" NOT NULL
);


ALTER TABLE "public"."story_moderation" OWNER TO "postgres";


ALTER TABLE "public"."story_moderation" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."story_moderation_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE OR REPLACE VIEW "public"."story_tags" WITH ("security_invoker"='on') AS
 SELECT "unnest"("story"."tags") AS "tag",
    "count"(*) AS "count"
   FROM "public"."story"
  GROUP BY ("unnest"("story"."tags"));


ALTER TABLE "public"."story_tags" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."story_view" WITH ("security_invoker"='on') AS
 SELECT "h"."id",
    "h"."inserted_at",
    "h"."updated_at",
    "h"."storyteller",
    "h"."user_id",
    "h"."tags",
    "h"."role",
    "h"."recording_link",
    "h"."transcription",
    "h"."image",
    "h"."template",
    "h"."pub_story_text",
    "h"."pub_quotes",
    "h"."pub_selected_images",
    "h"."insights_gpt",
    "h"."fts",
    "m"."status" AS "moderation_status"
   FROM ("public"."story" "h"
     JOIN "public"."story_moderation" "m" ON (("h"."id" = "m"."story_id")));


ALTER TABLE "public"."story_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_types" (
    "slug" "text" NOT NULL,
    "label" "text" NOT NULL,
    "is_default" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."user_types" OWNER TO "postgres";


ALTER TABLE ONLY "public"."branding"
    ADD CONSTRAINT "branding_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."events_interested"
    ADD CONSTRAINT "events_interested_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."events_interested"
    ADD CONSTRAINT "events_interested_user_id_event_id_key" UNIQUE ("user_id", "event_id");



ALTER TABLE ONLY "public"."events_moderation"
    ADD CONSTRAINT "events_moderation_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feature_flags"
    ADD CONSTRAINT "feature_flags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."howtos_moderation"
    ADD CONSTRAINT "howtos_moderation_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."howtos"
    ADD CONSTRAINT "howtos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."howtos_useful"
    ADD CONSTRAINT "howtos_useful_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."howtos_useful"
    ADD CONSTRAINT "howtos_useful_user_id_howto_id_key" UNIQUE ("user_id", "howto_id");



ALTER TABLE ONLY "public"."map_pins_moderation"
    ADD CONSTRAINT "map_pins_moderation_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."map_pins"
    ADD CONSTRAINT "map_pins_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_permission_key" UNIQUE ("role", "permission");



ALTER TABLE ONLY "public"."story_moderation"
    ADD CONSTRAINT "story_moderation_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."story"
    ADD CONSTRAINT "story_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_types"
    ADD CONSTRAINT "user_types_pkey" PRIMARY KEY ("slug");



CREATE INDEX "events_fts" ON "public"."events" USING "gin" ("fts");



CREATE INDEX "howtos_fts" ON "public"."howtos" USING "gin" ("fts");



CREATE INDEX "story_fts" ON "public"."story" USING "gin" ("fts");



CREATE UNIQUE INDEX "user_types_is_default_idx" ON "public"."user_types" USING "btree" ("is_default") WHERE "is_default";



CREATE OR REPLACE TRIGGER "event_notification_trigger" AFTER INSERT ON "public"."events_moderation" FOR EACH ROW EXECUTE FUNCTION "public"."handle_events_moderation_notification"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."branding" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."events" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."howtos" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."map_pins" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."story" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."story_moderation" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "howto_notification_trigger" AFTER INSERT ON "public"."howtos_moderation" FOR EACH ROW EXECUTE FUNCTION "public"."handle_howtos_moderation_notification"();



CREATE OR REPLACE TRIGGER "map_pin_notification_trigger" AFTER INSERT ON "public"."map_pins_moderation" FOR EACH ROW EXECUTE FUNCTION "public"."handle_map_pins_moderation_notification"();



CREATE OR REPLACE TRIGGER "on_events_insert" AFTER INSERT ON "public"."events" FOR EACH ROW EXECUTE FUNCTION "public"."handle_event_moderation_updates"();



CREATE OR REPLACE TRIGGER "on_events_update" AFTER UPDATE ON "public"."events" FOR EACH ROW EXECUTE FUNCTION "public"."handle_event_moderation_updates"();



CREATE OR REPLACE TRIGGER "on_howtos_insert" AFTER INSERT ON "public"."howtos" FOR EACH ROW EXECUTE FUNCTION "public"."handle_howto_moderation_updates"();



CREATE OR REPLACE TRIGGER "on_howtos_update" AFTER UPDATE ON "public"."howtos" FOR EACH ROW EXECUTE FUNCTION "public"."handle_howto_moderation_updates"();



CREATE OR REPLACE TRIGGER "on_map_pins_insert" AFTER INSERT ON "public"."map_pins" FOR EACH ROW EXECUTE FUNCTION "public"."handle_map_pin_moderation_updates"();



CREATE OR REPLACE TRIGGER "on_map_pins_update" AFTER UPDATE ON "public"."map_pins" FOR EACH ROW EXECUTE FUNCTION "public"."handle_map_pin_moderation_updates"();



CREATE OR REPLACE TRIGGER "on_story_insert" AFTER INSERT ON "public"."story" FOR EACH ROW EXECUTE FUNCTION "public"."handle_story_moderation_insert"();



ALTER TABLE ONLY "public"."events_interested"
    ADD CONSTRAINT "events_interested_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id");



ALTER TABLE ONLY "public"."events_interested"
    ADD CONSTRAINT "events_interested_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."events_moderation"
    ADD CONSTRAINT "events_moderation_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."events_moderation"
    ADD CONSTRAINT "events_moderation_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."howtos_moderation"
    ADD CONSTRAINT "howtos_moderation_howto_id_fkey" FOREIGN KEY ("howto_id") REFERENCES "public"."howtos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."howtos_moderation"
    ADD CONSTRAINT "howtos_moderation_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."howtos_useful"
    ADD CONSTRAINT "howtos_useful_howto_id_fkey" FOREIGN KEY ("howto_id") REFERENCES "public"."howtos"("id");



ALTER TABLE ONLY "public"."howtos_useful"
    ADD CONSTRAINT "howtos_useful_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."howtos"
    ADD CONSTRAINT "howtos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."map_pins_moderation"
    ADD CONSTRAINT "map_pins_moderation_map_pin_id_fkey" FOREIGN KEY ("map_pin_id") REFERENCES "public"."map_pins"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."map_pins_moderation"
    ADD CONSTRAINT "map_pins_moderation_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."map_pins"
    ADD CONSTRAINT "map_pins_story_id_fkey" FOREIGN KEY ("story_id") REFERENCES "public"."story"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_moderation"
    ADD CONSTRAINT "story_moderation_story_id_fkey" FOREIGN KEY ("story_id") REFERENCES "public"."story"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_moderation"
    ADD CONSTRAINT "story_moderation_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."story"
    ADD CONSTRAINT "story_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Allow admins to create user types" ON "public"."user_types" FOR INSERT WITH CHECK (( SELECT "public"."authorize"('user_types.update'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow admins to delete user types" ON "public"."user_types" FOR DELETE USING (( SELECT "public"."authorize"('user_types.update'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow admins to insert branding" ON "public"."branding" FOR INSERT WITH CHECK (( SELECT "public"."authorize"('branding.update'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow admins to insert features" ON "public"."feature_flags" FOR INSERT WITH CHECK (( SELECT "public"."authorize"('features.update'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow admins to update branding" ON "public"."branding" FOR UPDATE USING (( SELECT "public"."authorize"('branding.update'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow admins to update features" ON "public"."feature_flags" FOR UPDATE USING (( SELECT "public"."authorize"('features.update'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow admins to update user roles" ON "public"."user_roles" FOR UPDATE USING (( SELECT "public"."authorize"('user_roles.update'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow all users to read all profiles" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Allow all users to read all user roles" ON "public"."user_roles" FOR SELECT USING (true);



CREATE POLICY "Allow all users to read branding" ON "public"."branding" FOR SELECT USING (true);



CREATE POLICY "Allow all users to read features" ON "public"."feature_flags" FOR SELECT USING (true);



CREATE POLICY "Allow all users to read user types" ON "public"."user_types" FOR SELECT USING (true);



CREATE POLICY "Allow auth admin to read user roles" ON "public"."user_roles" FOR SELECT TO "supabase_auth_admin" USING (true);



CREATE POLICY "Allow moderators delete all events" ON "public"."events" FOR DELETE USING (( SELECT "public"."authorize"('events.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators delete all howtos" ON "public"."howtos" FOR DELETE USING (( SELECT "public"."authorize"('howtos.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators delete all map pins" ON "public"."map_pins" FOR DELETE USING (( SELECT "public"."authorize"('map.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators delete all stories" ON "public"."story" FOR DELETE USING (( SELECT "public"."authorize"('story.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators read all events" ON "public"."events" FOR SELECT USING (( SELECT "public"."authorize"('events.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators read all howtos" ON "public"."howtos" FOR SELECT USING (( SELECT "public"."authorize"('howtos.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators read all map pins" ON "public"."map_pins" FOR SELECT USING (( SELECT "public"."authorize"('map.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators read all stories" ON "public"."story" FOR SELECT USING (( SELECT "public"."authorize"('story.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators to create their own stories" ON "public"."story" FOR INSERT WITH CHECK ((( SELECT "public"."authorize"('story.create'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow moderators to insert all events moderation" ON "public"."events_moderation" FOR INSERT WITH CHECK (( SELECT "public"."authorize"('events.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators to insert all map pins moderation" ON "public"."map_pins_moderation" FOR INSERT WITH CHECK (( SELECT "public"."authorize"('map.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators to insert howtos moderation" ON "public"."howtos_moderation" FOR INSERT WITH CHECK (( SELECT "public"."authorize"('howtos.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators to read all events moderation" ON "public"."events_moderation" FOR SELECT USING (( SELECT "public"."authorize"('events.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators to read all howtos moderation" ON "public"."howtos_moderation" FOR SELECT USING (( SELECT "public"."authorize"('howtos.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators to read all map pins moderation" ON "public"."map_pins_moderation" FOR SELECT USING (( SELECT "public"."authorize"('map.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators to read all stories moderation" ON "public"."story_moderation" FOR SELECT USING (( SELECT "public"."authorize"('story.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators to update all stories moderation" ON "public"."story_moderation" FOR UPDATE USING (( SELECT "public"."authorize"('story.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators update all events" ON "public"."events" FOR UPDATE USING (( SELECT "public"."authorize"('events.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators update all howtos" ON "public"."howtos" FOR UPDATE USING (( SELECT "public"."authorize"('howtos.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators update all map pins" ON "public"."map_pins" FOR UPDATE USING (( SELECT "public"."authorize"('map.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow moderators update all stories" ON "public"."story" FOR UPDATE USING (( SELECT "public"."authorize"('story.moderate'::"public"."user_permission") AS "authorize"));



CREATE POLICY "Allow users to create their own events" ON "public"."events" FOR INSERT WITH CHECK ((( SELECT "public"."authorize"('events.create'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow users to create their own events interested" ON "public"."events_interested" FOR INSERT WITH CHECK ((( SELECT "public"."authorize"('events.create'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow users to create their own howtos" ON "public"."howtos" FOR INSERT WITH CHECK ((( SELECT "public"."authorize"('howtos.create'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow users to create their own howtos useful" ON "public"."howtos_useful" FOR INSERT WITH CHECK ((( SELECT "public"."authorize"('howtos.create'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow users to create their own map pins" ON "public"."map_pins" FOR INSERT WITH CHECK ((( SELECT "public"."authorize"('map.create'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow users to delete their own events" ON "public"."events" FOR DELETE USING ((( SELECT "public"."authorize"('events.delete'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow users to delete their own events interested" ON "public"."events_interested" FOR DELETE USING ((( SELECT "public"."authorize"('events.delete'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow users to delete their own howtos" ON "public"."howtos" FOR DELETE USING ((( SELECT "public"."authorize"('howtos.delete'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow users to delete their own howtos useful" ON "public"."howtos_useful" FOR DELETE USING ((( SELECT "public"."authorize"('howtos.delete'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow users to delete their own map pins" ON "public"."map_pins" FOR DELETE USING ((( SELECT "public"."authorize"('map.delete'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow users to delete their own stories" ON "public"."story" FOR DELETE USING ((( SELECT "public"."authorize"('story.delete'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id")));



CREATE POLICY "Allow users to read approved events" ON "public"."events" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."events_moderation"
  WHERE (("events_moderation"."event_id" = "events"."id") AND ("events_moderation"."status" = 'approved'::"public"."moderation_status")))));



CREATE POLICY "Allow users to read approved events moderation" ON "public"."events_moderation" FOR SELECT USING (("status" = 'approved'::"public"."moderation_status"));



CREATE POLICY "Allow users to read approved howtos" ON "public"."howtos" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."howtos_moderation"
  WHERE (("howtos_moderation"."howto_id" = "howtos"."id") AND ("howtos_moderation"."status" = 'approved'::"public"."moderation_status")))));



CREATE POLICY "Allow users to read approved howtos moderation" ON "public"."howtos_moderation" FOR SELECT USING (("status" = 'approved'::"public"."moderation_status"));



CREATE POLICY "Allow users to read approved map pins" ON "public"."map_pins" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."map_pins_moderation"
  WHERE (("map_pins_moderation"."map_pin_id" = "map_pins"."id") AND ("map_pins_moderation"."status" = 'approved'::"public"."moderation_status")))));



CREATE POLICY "Allow users to read approved map pins moderation" ON "public"."map_pins_moderation" FOR SELECT USING (("status" = 'approved'::"public"."moderation_status"));



CREATE POLICY "Allow users to read approved stories" ON "public"."story" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."story_moderation"
  WHERE (("story_moderation"."story_id" = "story"."id") AND ("story_moderation"."status" = 'approved'::"public"."moderation_status")))));



CREATE POLICY "Allow users to read approved stories moderation" ON "public"."story_moderation" FOR SELECT USING (("status" = 'approved'::"public"."moderation_status"));



CREATE POLICY "Allow users to read their own events" ON "public"."events" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to read their own events interested" ON "public"."events_interested" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to read their own events moderation" ON "public"."events_moderation" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to read their own howtos" ON "public"."howtos" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to read their own howtos moderation" ON "public"."howtos_moderation" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to read their own howtos useful" ON "public"."howtos_useful" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to read their own map pins" ON "public"."map_pins" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to read their own map pins moderation" ON "public"."map_pins_moderation" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to read their own notifications" ON "public"."notifications" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Allow users to update their own events" ON "public"."events" FOR UPDATE USING ((( SELECT "public"."authorize"('events.update'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id"))) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to update their own howtos" ON "public"."howtos" FOR UPDATE USING ((( SELECT "public"."authorize"('howtos.update'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id"))) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to update their own map pins" ON "public"."map_pins" FOR UPDATE USING ((( SELECT "public"."authorize"('map.update'::"public"."user_permission") AS "authorize") AND ("auth"."uid"() = "user_id"))) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to update their own profiles" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



ALTER TABLE "public"."branding" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."events_interested" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."events_moderation" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."feature_flags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."howtos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."howtos_moderation" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."howtos_useful" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."map_pins" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."map_pins_moderation" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."role_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."story" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."story_moderation" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_types" ENABLE ROW LEVEL SECURITY;


ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";
GRANT USAGE ON SCHEMA "public" TO "supabase_auth_admin";

GRANT ALL ON FUNCTION "public"."authorize"("requested_permission" "public"."user_permission") TO "anon";
GRANT ALL ON FUNCTION "public"."authorize"("requested_permission" "public"."user_permission") TO "authenticated";
GRANT ALL ON FUNCTION "public"."authorize"("requested_permission" "public"."user_permission") TO "service_role";

REVOKE ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "supabase_auth_admin";

GRANT ALL ON FUNCTION "public"."get_event_interest_count"("event_id" bigint, "user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_event_interest_count"("event_id" bigint, "user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_event_interest_count"("event_id" bigint, "user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_howto_useful_count"("howto_id" bigint, "user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_howto_useful_count"("howto_id" bigint, "user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_howto_useful_count"("howto_id" bigint, "user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_event_moderation_updates"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_event_moderation_updates"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_event_moderation_updates"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_events_moderation_notification"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_events_moderation_notification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_events_moderation_notification"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_howto_moderation_updates"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_howto_moderation_updates"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_howto_moderation_updates"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_howtos_moderation_notification"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_howtos_moderation_notification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_howtos_moderation_notification"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_map_pin_moderation_updates"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_map_pin_moderation_updates"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_map_pin_moderation_updates"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_map_pins_moderation_notification"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_map_pins_moderation_notification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_map_pins_moderation_notification"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_story_moderation_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_story_moderation_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_story_moderation_insert"() TO "service_role";

GRANT ALL ON FUNCTION "public"."update_user_types"("types" "public"."user_type"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."update_user_types"("types" "public"."user_type"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_user_types"("types" "public"."user_type"[]) TO "service_role";

GRANT ALL ON FUNCTION "public"."verify_user_password"("password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."verify_user_password"("password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."verify_user_password"("password" "text") TO "service_role";

GRANT ALL ON TABLE "public"."branding" TO "anon";
GRANT ALL ON TABLE "public"."branding" TO "authenticated";
GRANT ALL ON TABLE "public"."branding" TO "service_role";

GRANT ALL ON SEQUENCE "public"."branding_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."branding_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."branding_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."events" TO "anon";
GRANT ALL ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";

GRANT ALL ON SEQUENCE "public"."events_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."events_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."events_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."events_interested" TO "anon";
GRANT ALL ON TABLE "public"."events_interested" TO "authenticated";
GRANT ALL ON TABLE "public"."events_interested" TO "service_role";

GRANT ALL ON SEQUENCE "public"."events_interested_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."events_interested_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."events_interested_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."events_moderation" TO "anon";
GRANT ALL ON TABLE "public"."events_moderation" TO "authenticated";
GRANT ALL ON TABLE "public"."events_moderation" TO "service_role";

GRANT ALL ON SEQUENCE "public"."events_moderation_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."events_moderation_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."events_moderation_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."events_tags" TO "anon";
GRANT ALL ON TABLE "public"."events_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."events_tags" TO "service_role";

GRANT ALL ON TABLE "public"."latest_events_moderation" TO "anon";
GRANT ALL ON TABLE "public"."latest_events_moderation" TO "authenticated";
GRANT ALL ON TABLE "public"."latest_events_moderation" TO "service_role";

GRANT ALL ON TABLE "public"."events_view" TO "anon";
GRANT ALL ON TABLE "public"."events_view" TO "authenticated";
GRANT ALL ON TABLE "public"."events_view" TO "service_role";

GRANT ALL ON TABLE "public"."feature_flags" TO "anon";
GRANT ALL ON TABLE "public"."feature_flags" TO "authenticated";
GRANT ALL ON TABLE "public"."feature_flags" TO "service_role";

GRANT ALL ON TABLE "public"."howtos" TO "anon";
GRANT ALL ON TABLE "public"."howtos" TO "authenticated";
GRANT ALL ON TABLE "public"."howtos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."howtos_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."howtos_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."howtos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."howtos_moderation" TO "anon";
GRANT ALL ON TABLE "public"."howtos_moderation" TO "authenticated";
GRANT ALL ON TABLE "public"."howtos_moderation" TO "service_role";

GRANT ALL ON SEQUENCE "public"."howtos_moderation_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."howtos_moderation_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."howtos_moderation_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."howtos_tags" TO "anon";
GRANT ALL ON TABLE "public"."howtos_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."howtos_tags" TO "service_role";

GRANT ALL ON TABLE "public"."howtos_useful" TO "anon";
GRANT ALL ON TABLE "public"."howtos_useful" TO "authenticated";
GRANT ALL ON TABLE "public"."howtos_useful" TO "service_role";

GRANT ALL ON SEQUENCE "public"."howtos_useful_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."howtos_useful_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."howtos_useful_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."latest_howtos_moderation" TO "anon";
GRANT ALL ON TABLE "public"."latest_howtos_moderation" TO "authenticated";
GRANT ALL ON TABLE "public"."latest_howtos_moderation" TO "service_role";

GRANT ALL ON TABLE "public"."howtos_view" TO "anon";
GRANT ALL ON TABLE "public"."howtos_view" TO "authenticated";
GRANT ALL ON TABLE "public"."howtos_view" TO "service_role";

GRANT ALL ON TABLE "public"."map_pins_moderation" TO "anon";
GRANT ALL ON TABLE "public"."map_pins_moderation" TO "authenticated";
GRANT ALL ON TABLE "public"."map_pins_moderation" TO "service_role";

GRANT ALL ON TABLE "public"."latest_map_pins_moderation" TO "anon";
GRANT ALL ON TABLE "public"."latest_map_pins_moderation" TO "authenticated";
GRANT ALL ON TABLE "public"."latest_map_pins_moderation" TO "service_role";

GRANT ALL ON TABLE "public"."map_pins" TO "anon";
GRANT ALL ON TABLE "public"."map_pins" TO "authenticated";
GRANT ALL ON TABLE "public"."map_pins" TO "service_role";

GRANT ALL ON SEQUENCE "public"."map_pins_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."map_pins_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."map_pins_id_seq" TO "service_role";

GRANT ALL ON SEQUENCE "public"."map_pins_moderation_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."map_pins_moderation_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."map_pins_moderation_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."map_pins_view" TO "anon";
GRANT ALL ON TABLE "public"."map_pins_view" TO "authenticated";
GRANT ALL ON TABLE "public"."map_pins_view" TO "service_role";

GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";

GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";

GRANT ALL ON TABLE "public"."user_roles" TO "anon";
GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";
GRANT ALL ON TABLE "public"."user_roles" TO "supabase_auth_admin";

GRANT ALL ON TABLE "public"."profiles_view" TO "anon";
GRANT ALL ON TABLE "public"."profiles_view" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles_view" TO "service_role";

GRANT ALL ON TABLE "public"."role_permissions" TO "anon";
GRANT ALL ON TABLE "public"."role_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permissions" TO "service_role";

GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."story" TO "anon";
GRANT ALL ON TABLE "public"."story" TO "authenticated";
GRANT ALL ON TABLE "public"."story" TO "service_role";

GRANT ALL ON SEQUENCE "public"."story_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."story_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."story_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."story_moderation" TO "anon";
GRANT ALL ON TABLE "public"."story_moderation" TO "authenticated";
GRANT ALL ON TABLE "public"."story_moderation" TO "service_role";

GRANT ALL ON SEQUENCE "public"."story_moderation_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."story_moderation_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."story_moderation_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."story_tags" TO "anon";
GRANT ALL ON TABLE "public"."story_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."story_tags" TO "service_role";

GRANT ALL ON TABLE "public"."story_view" TO "anon";
GRANT ALL ON TABLE "public"."story_view" TO "authenticated";
GRANT ALL ON TABLE "public"."story_view" TO "service_role";

GRANT ALL ON TABLE "public"."user_types" TO "anon";
GRANT ALL ON TABLE "public"."user_types" TO "authenticated";
GRANT ALL ON TABLE "public"."user_types" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;