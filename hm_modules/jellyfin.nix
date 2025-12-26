{ config, pkgs, ... }:

let
  # Configuration variables - adjust these to your needs
  mediaDir = "/srv/media";
  configDir = "${config.home.homeDirectory}/.config/media-server";
  
  # User/Group IDs - use your actual user IDs
  uid = "1000";
  gid = "100";
  
  # Network configuration
  vpnProvider = "nordvpn";
  
in {
  # Install required packages
  home.packages = with pkgs; [
    docker-compose
  ];

  # Create media directories with proper permissions
  # Note: This creates directories in your home, but if mediaDir is outside home,
  # you'll need to handle this in your system configuration instead
  # home.activation.createMediaDirs = config.lib.dag.entryAfter ["writeBoundary"] ''
  #   $DRY_RUN_CMD mkdir -p ${mediaDir}/{movies,tvshows,downloads/{torrents,incomplete}}
  #   $DRY_RUN_CMD chmod -R 775 ${mediaDir}
  # '';

  # Create necessary directories
  home.file."${configDir}/docker-compose.yml".text = ''
    services:
      # Gluetun - VPN container for secure downloads
      gluetun:
        image: qmcgaw/gluetun:latest
        container_name: gluetun
        cap_add:
          - NET_ADMIN
        devices:
          - /dev/net/tun:/dev/net/tun
        ports:
          - "8080:8080"  # qBittorrent WebUI
          - "6881:6881"  # qBittorrent TCP
          - "6881:6881/udp"  # qBittorrent UDP
        env_file:
          - ./secrets.env
        environment:
          - VPN_SERVICE_PROVIDER=${vpnProvider}
          - VPN_TYPE=openvpn
          - SERVER_COUNTRIES=United States
          - FIREWALL_OUTBOUND_SUBNETS=172.20.0.0/16  # Allow local network
          - TZ=America/Denver
        volumes:
          - ${configDir}/gluetun:/gluetun
        restart: unless-stopped
        networks:
          - media-network

      # qBittorrent - Download client (routed through VPN)
      qbittorrent:
        image: lscr.io/linuxserver/qbittorrent:latest
        container_name: qbittorrent
        network_mode: "service:gluetun"
        environment:
          - PUID=${uid}
          - PGID=${gid}
          - TZ=America/Denver
          - WEBUI_PORT=8080
        volumes:
          - ${configDir}/qbittorrent:/config
          - ${mediaDir}:/data
        depends_on:
          - gluetun
        restart: unless-stopped

      # Prowlarr - Indexer manager
      prowlarr:
        image: lscr.io/linuxserver/prowlarr:latest
        container_name: prowlarr
        environment:
          - PUID=${uid}
          - PGID=${gid}
          - TZ=America/Denver
        volumes:
          - ${configDir}/prowlarr:/config
        ports:
          - "9696:9696"
        restart: unless-stopped
        networks:
          - media-network

      # Radarr - Movie management
      radarr:
        image: lscr.io/linuxserver/radarr:latest
        container_name: radarr
        environment:
          - PUID=${uid}
          - PGID=${gid}
          - TZ=America/Denver
        volumes:
          - ${configDir}/radarr:/config
          - ${mediaDir}:/data
        ports:
          - "7878:7878"
        restart: unless-stopped
        networks:
          - media-network

      # Sonarr - TV show management
      sonarr:
        image: lscr.io/linuxserver/sonarr:latest
        container_name: sonarr
        environment:
          - PUID=${uid}
          - PGID=${gid}
          - TZ=America/Denver
        volumes:
          - ${configDir}/sonarr:/config
          - ${mediaDir}:/data
        ports:
          - "8989:8989"
        restart: unless-stopped
        networks:
          - media-network

      # Bazarr - Subtitle management
      bazarr:
        image: lscr.io/linuxserver/bazarr:latest
        container_name: bazarr
        environment:
          - PUID=${uid}
          - PGID=${gid}
          - TZ=America/Denver
        volumes:
          - ${configDir}/bazarr:/config
          - ${mediaDir}:/data
        ports:
          - "6767:6767"
        restart: unless-stopped
        networks:
          - media-network

      # Jellyfin - Media server
      jellyfin:
        image: jellyfin/jellyfin:latest
        container_name: jellyfin
        environment:
          - PUID=${uid}
          - PGID=${gid}
          - TZ=America/Denver
        volumes:
          - ${configDir}/jellyfin:/config
          - ${configDir}/jellyfin/cache:/cache
          - ${mediaDir}/movies:/data/movies:ro
          - ${mediaDir}/tvshows:/data/tvshows:ro
        ports:
          - "8096:8096"  # HTTP WebUI
          - "8920:8920"  # HTTPS WebUI (optional)
          - "7359:7359/udp"  # Network discovery
          - "1900:1900/udp"  # DLNA
        devices:
          - /dev/dri:/dev/dri  # Hardware acceleration (if available)
        restart: unless-stopped
        networks:
          - media-network

      # Jellyseerr - Request management
      jellyseerr:
        image: fallenbagel/jellyseerr:latest
        container_name: jellyseerr
        environment:
          - LOG_LEVEL=info
          - TZ=America/Denver
        volumes:
          - ${configDir}/jellyseerr:/app/config
        ports:
          - "5055:5055"
        restart: unless-stopped
        networks:
          - media-network

    networks:
      media-network:
        driver: bridge
  '';

  # Create a setup script
  home.file."${configDir}/setup.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -e

      echo "Setting up media server directories..."
      
      # Create media directories
      mkdir -p ${mediaDir}/{movies,tvshows,downloads/{incomplete,complete}}
      
      # Create config directories
      mkdir -p ${configDir}/{gluetun,qbittorrent,prowlarr,radarr,sonarr,bazarr,jellyfin,jellyseerr}
      
      echo "Directories created successfully!"
      echo ""
      
      # Check if secrets.env exists
      if [ ! -f "${configDir}/secrets.env" ]; then
        echo "⚠️  WARNING: secrets.env not found!"
        echo "Creating template at ${configDir}/secrets.env"
        echo ""
        cat > "${configDir}/secrets.env" << 'EOF'
NORDVPN_USER=your_nordvpn_service_username
NORDVPN_PASSWORD=your_nordvpn_service_password
EOF
        echo "📝 Please edit ${configDir}/secrets.env with your NordVPN service credentials"
        echo "   Get them from: https://my.nordaccount.com/dashboard/nordvpn/"
        echo "   (Manual Setup section)"
        echo ""
        exit 1
      fi
      
      echo "✓ secrets.env found"
      echo ""
      echo "Next steps:"
      echo "1. Run: cd ${configDir} && docker-compose up -d"
      echo ""
      echo "Service URLs:"
      echo "  - Jellyfin:     http://localhost:8096"
      echo "  - Jellyseerr:   http://localhost:5055"
      echo "  - Radarr:       http://localhost:7878"
      echo "  - Sonarr:       http://localhost:8989"
      echo "  - Prowlarr:     http://localhost:9696"
      echo "  - Bazarr:       http://localhost:6767"
      echo "  - qBittorrent:  http://localhost:8080"
      echo ""
      echo "IMPORTANT: Configure Prowlarr first, then add it to Radarr/Sonarr!"
      echo "Follow the configuration guide: https://yams.media/config/"
    '';
    executable = true;
  };

  # Create a management script
  home.file."${configDir}/media-server" = {
    text = ''
      #!/usr/bin/env bash
      
      COMPOSE_FILE="${configDir}/docker-compose.yml"
      
      case "$1" in
        start)
          docker-compose -f "$COMPOSE_FILE" up -d
          echo "Media server started!"
          ;;
        stop)
          docker-compose -f "$COMPOSE_FILE" down
          echo "Media server stopped!"
          ;;
        restart)
          docker-compose -f "$COMPOSE_FILE" restart
          echo "Media server restarted!"
          ;;
        logs)
          docker-compose -f "$COMPOSE_FILE" logs -f "''${2:-}"
          ;;
        status)
          docker-compose -f "$COMPOSE_FILE" ps
          ;;
        update)
          docker-compose -f "$COMPOSE_FILE" pull
          docker-compose -f "$COMPOSE_FILE" up -d
          echo "Media server updated!"
          ;;
        check-vpn)
          echo "Checking VPN status..."
          echo ""
          
          # Get VPN IP
          echo "🔒 VPN IP (qBittorrent/Gluetun):"
          VPN_INFO=$(docker exec gluetun wget -qO- https://ipinfo.io/json 2>/dev/null)
          if [ $? -eq 0 ]; then
            VPN_IP=$(echo "$VPN_INFO" | sed -n 's/.*"ip": *"\([^"]*\)".*/\1/p')
            VPN_COUNTRY=$(echo "$VPN_INFO" | sed -n 's/.*"country": *"\([^"]*\)".*/\1/p')
            VPN_CITY=$(echo "$VPN_INFO" | sed -n 's/.*"city": *"\([^"]*\)".*/\1/p')
            echo "   IP: $VPN_IP"
            echo "   Country: $VPN_COUNTRY"
            echo "   City: $VPN_CITY"
          else
            echo "   ❌ Failed to get VPN IP - is Gluetun running?"
            exit 1
          fi
          
          echo ""
          
          # Get local IP
          echo "🏠 Your Local IP:"
          LOCAL_INFO=$(curl -s https://ipinfo.io/json 2>/dev/null)
          if [ $? -eq 0 ]; then
            LOCAL_IP=$(echo "$LOCAL_INFO" | sed -n 's/.*"ip": *"\([^"]*\)".*/\1/p')
            LOCAL_COUNTRY=$(echo "$LOCAL_INFO" | sed -n 's/.*"country": *"\([^"]*\)".*/\1/p')
            LOCAL_CITY=$(echo "$LOCAL_INFO" | sed -n 's/.*"city": *"\([^"]*\)".*/\1/p')
            echo "   IP: $LOCAL_IP"
            echo "   Country: $LOCAL_COUNTRY"
            echo "   City: $LOCAL_CITY"
          else
            echo "   ❌ Failed to get local IP"
            exit 1
          fi
          
          echo ""
          
          # Compare IPs
          if [ -n "$VPN_IP" ] && [ -n "$LOCAL_IP" ] && [ "$VPN_IP" != "$LOCAL_IP" ]; then
            echo "✅ Your IPs are different. qBittorrent is working as expected!"
          else
            echo "⚠️  WARNING: Your IPs are the SAME. VPN may not be working correctly!"
            exit 1
          fi
          ;;
        *)
          echo "Usage: $0 {start|stop|restart|logs|status|update}"
          echo ""
          echo "Commands:"
          echo "  start   - Start all services"
          echo "  stop    - Stop all services"
          echo "  restart - Restart all services"
          echo "  logs    - View logs (optionally specify service name)"
          echo "  status  - Show service status"
          echo "  update  - Pull latest images and restart"
          exit 1
          ;;
      esac
    '';
    executable = true;
  };

  # Add management script to PATH
  home.sessionPath = [ "${configDir}" ];

  # Create .gitignore for secrets
  home.file."${configDir}/.gitignore".text = ''
    secrets.env
  '';

  # Create secrets template (this goes in git as an example)
  home.file."${configDir}/secrets.env.example".text = ''
    # NordVPN Service Credentials
    # Get these from: https://my.nordaccount.com/dashboard/nordvpn/
    # Go to Services → NordVPN → Manual Setup
    # Gluetun uses OPENVPN_USER and OPENVPN_PASSWORD for NordVPN
    OPENVPN_USER=your_nordvpn_service_username
    OPENVPN_PASSWORD=your_nordvpn_service_password
  '';
}
