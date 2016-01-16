

dev:
	mix phoenix.digest
	mix phoenix.server

prod:
	mix deps.get --only prod
	MIX_ENV=prod mix phoenix.digest
	PORT=4000 GOL_ENDPOINT_SECRET_KEY_BASE=$(GOL_ENDPOINT_SECRET_KEY_BASE) MIX_ENV=prod elixir --detached -S mix do compile, phoenix.server
