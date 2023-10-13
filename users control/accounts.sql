-- This table is intended for storing data related to user authorization data.
CREATE TABLE public.accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username TEXT UNIQUE NOT NULL CHECK (length(username) > 3),
    password TEXT NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.confirmations (
    client BIGINT PRIMARY KEY,
    confirmation SMALLINT NOT NULL DEFAULT 0,
    email TEXT UNIQUE,
    emails TEXT[],
    phone TEXT UNIQUE,
    FOREIGN KEY (client) REFERENCES public.accounts (id)
);

-- This table stores the dates of changes to user authorization data.
CREATE TABLE public.accounts_changes (
    client BIGINT PRIMARY KEY,
    username TIMESTAMP[],
    password TIMESTAMP[],
    email TIMESTAMP[],
    phone TIMESTAMP[],
    FOREIGN KEY (client) REFERENCES public.accounts (id)
);

-- This table stores information about bots
CREATE TABLE public.bots (
    client BIGINT PRIMARY KEY,
    owner BIGINT NOT NULL,
    FOREIGN KEY (client) REFERENCES public.accounts (id),
    FOREIGN KEY (owner) REFERENCES public.accounts (id)
);