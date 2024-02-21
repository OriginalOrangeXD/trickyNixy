{ pkgs, ... }:
{
  config.services.postgresql = {
    enable = true;
    ensureDatabases = [ "mydb" ];
    authentication = pkgs.lib.mkOverride 10 ''
	# TYPE  DATABASE        USER            ADDRESS                 METHOD
	local   all             all                                     trust
	host    all             all             127.0.0.1/32            trust
	host    all             all             ::1/128                 trust
'';
  };
}
