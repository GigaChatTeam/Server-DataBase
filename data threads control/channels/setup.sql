CREATE TABLE channels."index" (
    "id" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "owner" BIGINT NOT NULL,
    title TEXT NOT NULL CHECK (length(title) > 2 AND length(title) < 33),
    description TEXT CHECK (length(description) < 257),
    avatar BIGINT,
    created TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT TIMEZONE('UTC', now()),
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    "public" BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY ("owner") REFERENCES users.accounts ("id"),
    FOREIGN KEY (avatar) REFERENCES files."index" ("id")
);

CREATE TABLE channels.messages (
    channel BIGINT NOT NULL,
    posted TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT TIMEZONE('UTC', now()),
    author BIGINT NOT NULL,
    alias UUID,
    "type" TEXT,
    deleted TIMESTAMP WITHOUT TIME ZONE,
    deleted_reason TEXT,
    PRIMARY KEY (channel, posted),
    FOREIGN KEY (author) REFERENCES users.accounts ("id"),
    FOREIGN KEY (alias) REFERENCES users.aliases ("id"),
    FOREIGN KEY (channel) REFERENCES channels."index" ("id")
) PARTITION BY RANGE (posted);

CREATE TABLE channels.messages_data (
    channel BIGINT NOT NULL,
    original TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    edited TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    data TEXT,
    version SMALLINT NOT NULL DEFAULT 1,
    PRIMARY KEY (channel, original, version),
    FOREIGN KEY (channel, original) REFERENCES channels.messages (channel, posted)
) PARTITION BY RANGE (original);

CREATE TABLE channels.messages_attachments_media (
    file BIGINT NOT NULL,
    channel BIGINT NOT NULL,
    original TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    x SMALLINT[2] NOT NULL,
    y SMALLINT[2] NOT NULL,
    version SMALLINT NOT NULL DEFAULT 1,
    PRIMARY KEY (file, channel, original, version),
    FOREIGN KEY (file) REFERENCES files."index" ("id"),
    FOREIGN KEY (channel, original, version) REFERENCES channels.messages_data (channel, original, version)
) PARTITION BY RANGE (original);

CREATE TABLE channels.messages_attachments_files (
    file BIGINT NOT NULL,
    channel BIGINT NOT NULL,
    original TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    position SMALLINT NOT NULL,
    version SMALLINT NOT NULL DEFAULT 1,
    PRIMARY KEY (file, channel, original, version),
    UNIQUE (channel, original, position, version),
    FOREIGN KEY (file) REFERENCES files."index" ("id"),
    FOREIGN KEY (channel, original, version) REFERENCES channels.messages_data (channel, original, version)
) PARTITION BY RANGE (original);

CREATE TABLE channels."users" (
    client BIGINT NOT NULL,
    channel BIGINT NOT NULL,
    joined TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    reason TEXT,
    FOREIGN KEY (client) REFERENCES users.accounts ("id"),
    FOREIGN KEY (channel) REFERENCES channels.index ("id")
);

CREATE TABLE channels."groups" (
    "id" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel BIGINT NOT NULL,
    title TEXT NOT NULL,
    primacy SMALLINT NOT NULL,
    UNIQUE (channel, primacy),
    FOREIGN KEY (channel) REFERENCES channels.index ("id")
);

CREATE TABLE channels.users2groups (
    client BIGINT NOT NULL,
    "group" BIGINT NOT NULL,
    FOREIGN KEY (client) REFERENCES users.accounts ("id"),
    FOREIGN KEY ("group") REFERENCES channels."groups" ("id") ON DELETE CASCADE
);

CREATE TABLE channels.permissions_users (
    client BIGINT NOT NULL,
    channel BIGINT NOT NULL,
    permission INTEGER NOT NULL,
    status BOOLEAN,
    PRIMARY KEY (client, channel, permission),
    FOREIGN KEY (client) REFERENCES users.accounts ("id"),
    FOREIGN KEY (channel) REFERENCES channels.index ("id")
);

CREATE TABLE channels.permissions_groups (
    "group" BIGINT NOT NULL,
    channel BIGINT NOT NULL,
    permission INTEGER NOT NULL,
    status BOOLEAN,
    PRIMARY KEY ("group", channel, permission),
    FOREIGN KEY ("group") REFERENCES channels."groups" ("id") ON DELETE CASCADE,
    FOREIGN KEY (channel) REFERENCES channels.index ("id")
);

CREATE TABLE channels.invitations (
    creator BIGINT NOT NULL,
    channel BIGINT NOT NULL,
    uri TEXT DEFAULT substring(md5(public.uuid_generate_v4()::text), 0, 9) PRIMARY KEY,
    created TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT TIMEZONE('UTC', now()),
    expiration TIMESTAMP WITHOUT TIME ZONE,
    permitted_uses INTEGER,
    total_uses INTEGER NOT NULL DEFAULT 0,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (creator) REFERENCES users.accounts ("id"),
    FOREIGN KEY (channel) REFERENCES channels.index ("id"),
    CHECK (COALESCE(permitted_uses, 'Infinity'::NUMERIC) > total_uses)
);