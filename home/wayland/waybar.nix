{ config, pkgs, ... }: {
  config = {
    home.packages = with pkgs; [ material-design-icons nerdfonts ];
    programs.waybar = {
      enable = true;
      package = pkgs.waybar;
	  };
	};
}
