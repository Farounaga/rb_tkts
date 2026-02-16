require 'erb'
require 'fileutils'
require 'time'
require 'json'
require 'date'  # ajout pour Date.commercial
# === Auto-chargement .env ===
begin
  require 'dotenv'
  Dotenv.load(File.join(__dir__, '.env'))
rescue LoadError
  env_path = File.join(__dir__, '.env')
  if File.exist?(env_path)
    File.foreach(env_path) do |l|
      next if l.strip.empty? || l.lstrip.start_with?('#')
      k,v = l.split('=',2)
      next unless k && v
      ENV[k.strip] ||= v.strip
    end
  end
end
require_relative 'calculs'
require_relative 'xml_handler'

module Visualiser
  def self.generate_html_report(tickets, output_path = "output/visualisation.html")
    total_tickets = tickets.size
    total_comments = tickets.sum { |t| t[:comments].size }
    average_comments = total_tickets.zero? ? 0 : total_comments.to_f / total_tickets

    all_comment_texts = tickets.flat_map { |t| t[:comments].map { |c| c[:value].to_s.strip } }
    average_comment_length = all_comment_texts.map(&:length).sum / (all_comment_texts.size.nonzero? || 1)

    solved_count = tickets.count { |t| t[:solved_at] && !t[:solved_at].empty? }
    public_comments = tickets.sum { |t| t[:comments].count { |c| c[:is_public] == "true" } }

    dates = tickets.map { |t| t[:created_at] }.compact.map { |d| Time.parse(d) rescue nil }.compact
    first_date = dates.min
    last_date = dates.max


    top_tickets_by_description = tickets.select { |t| t[:description] }
                                        .sort_by { |t| t[:description].length }
                                        .reverse
                                        .first(5)

    requester_stats = Hash.new(0)
    tickets.each { |t| requester_stats[t[:requester_id]] += 1 if t[:requester_id] }
    top_requesters = requester_stats.sort_by { |_, count| -count }.first(10)

    cluster_topics_path = "cluster_topics.json"
    cluster_topics = File.exist?(cluster_topics_path) ? JSON.parse(File.read(cluster_topics_path)) : {}

    clusters_path = "clusters.json"
    cluster_counts = if File.exist?(clusters_path)
      JSON.parse(File.read(clusters_path)).values.each_with_object(Hash.new(0)) { |cluster_id, counts| counts[cluster_id.to_s] += 1 }
    else
      {}
    end


        # Grouper par jour
    tickets_per_day = Hash.new(0)
    tickets.each do |t|
      begin
        date = Time.parse(t[:created_at]).strftime('%Y-%m-%d') rescue next
        tickets_per_day[date] += 1
      end
    end

    # Trie par date
    tickets_per_day = tickets_per_day.sort.to_h
    chart_labels = tickets_per_day.keys
    chart_values = tickets_per_day.values

        cumulative_values = []
    sum = 0
    chart_values.each do |val|
      sum += val
      cumulative_values << sum
    end

    # === AJOUT: epochs pour les dates (axe X uPlot) ===
    day_epochs = chart_labels.map do |d|
      begin
        Time.parse(d).to_i
      rescue
        0
      end
    end

    # Calcul de réponses par membre d'équipe
    #
    replies = tickets.flat_map { |t| t[:comments] }

    # --- Auth Zendesk depuis ENV (.env) ---
    required_keys = %w[ZENDESK_EMAIL ZENDESK_API_TOKEN ZENDESK_SUBDOMAIN]
    missing = required_keys.reject { |k| ENV[k] && !ENV[k].empty? }
    staff_fetch_error = nil
    staff_hash = {}

    if missing.any?
      warn "⚠️ Variables d'environnement manquantes: #{missing.join(', ')}"
    else
      raw_email  = ENV['ZENDESK_EMAIL']
      add_suffix = ENV.fetch('ZENDESK_ADD_TOKEN_SUFFIX', 'true') != 'false'
      email      = add_suffix && !raw_email.end_with?('/token') ? "#{raw_email}/token" : raw_email
      api_token  = ENV['ZENDESK_API_TOKEN']
      subdomain  = ENV['ZENDESK_SUBDOMAIN']

      begin
        staff_hash = ZendeskAPI.get_agents_and_admins(subdomain, email, api_token)
      rescue => e
        staff_fetch_error = e.message
        warn "⚠️ Échec Zendesk (#{e.class}): #{e.message}"
      end
    end

    id_to_name = staff_hash.is_a?(Hash) ? staff_hash.invert : {}

    author_counts = Hash.new(0)
    replies.each do |reply|
      aid = reply[:author_id].to_i
      author_counts[aid] += 1 if aid != 0
    end

    reponses_par_membre = {}
    if staff_fetch_error.nil? && !id_to_name.empty?
      author_counts.each do |id, count|
        name = id_to_name[id]
        reponses_par_membre[name] = count if name
      end
      reponses_par_membre = reponses_par_membre.sort_by { |_, c| -c }.to_h
    end
    # puts reponses_par_membre  # debug si besoin


    top_tickets = tickets.select { |t| t[:comments].size > 0 }
                     .sort_by { |t| -t[:comments].size }
                     .first(100)

    columns_count = 4
    ticket_columns = top_tickets.each_slice((top_tickets.size / columns_count.to_f).ceil).to_a

    months, datasets = TicketTagStats.build_tag_datasets_weekly(tickets)

    # Epoch (début de période) pour le graphique des étiquettes
    tag_epochs = months.map do |lbl|
      begin
        case lbl
        when /\A\d{4}-\d{2}-\d{2}\z/
          Time.parse(lbl).to_i
        when /\A\d{4}-W(\d{2})\z/
          year = lbl[0,4].to_i
            week = $1.to_i
          Date.commercial(year, week, 1).to_time.to_i  # lundi ISO
        else
          Time.parse(lbl).to_i
        end
      rescue
        0
      end
    end


    template = <<-HTML
    <!DOCTYPE html>
    <html lang="fr">
    <head>
      <meta charset="UTF-8">
      <title>Dashboard Tickets</title>
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <!-- uPlot -->
      <link rel="stylesheet" href="https://unpkg.com/uplot/dist/uPlot.min.css">
      <script src="https://unpkg.com/uplot/dist/uPlot.iife.min.js"></script>
      <style>
        :root {
          --bg: hsl(0 0% 100%);
          --bg-alt: hsl(210 40% 98%);
          --border: hsl(214 32% 91%);
          --border-strong: hsl(216 34% 80%);
          --card: hsl(0 0% 100%);
          --card-hover: hsl(210 40% 97%);
          --fg: hsl(222 47% 11%);
          --fg-muted: hsl(215 16% 47%);
          --accent: hsl(221 83% 53%);
          --accent-fg: #fff;
          --danger: hsl(0 72% 50%);
          --warn: hsl(38 92% 50%);
          --ok: hsl(142 72% 35%);
          --radius: 12px;
          --shadow: 0 2px 4px rgba(0,0,0,.04),0 6px 16px -4px rgba(0,0,0,.08);
          color-scheme: light;
        }
        .dark {
          --bg: hsl(222 47% 7%);
          --bg-alt: hsl(222 47% 9%);
          --border: hsl(216 34% 17%);
          --border-strong: hsl(213 30% 30%);
          --card: hsl(222 47% 8.5%);
          --card-hover: hsl(222 47% 12%);
          --fg: hsl(0 0% 96%);
          --fg-muted: hsl(215 16% 65%);
          --accent: hsl(221 83% 60%);
          --accent-fg: #fff;
          --shadow: 0 0 0 1px hsl(216 34% 20%),0 4px 18px -4px rgba(0,0,0,.55);
          color-scheme: dark;
        }
        * { box-sizing:border-box; }
        body {
          margin:0;
          font-family: system-ui,-apple-system,Segoe UI,Roboto,'Inter',Ubuntu,sans-serif;
          background:var(--bg-alt);
          color:var(--fg);
          line-height:1.35;
        }
        header {
          position:sticky; top:0; z-index:50;
          display:flex; align-items:center; gap:.75rem;
          padding:.75rem 1.25rem;
          background:var(--bg);
          border-bottom:1px solid var(--border);
          backdrop-filter:blur(12px);
        }
        header h1 {
          font-size:1rem;
          font-weight:600;
          letter-spacing:.5px;
          margin:0;
        }
        header .spacer { flex:1; }
        button, input {
          font:inherit;
        }
        .btn {
          background:var(--accent);
          color:var(--accent-fg);
          border:1px solid var(--accent);
          padding:.5rem .85rem;
          font-size:.75rem;
          font-weight:500;
          border-radius:8px;
          cursor:pointer;
          display:inline-flex;
          align-items:center;
          gap:.35rem;
          transition:.18s background,.18s box-shadow;
        }
        .btn:hover { filter:brightness(1.07); }
        .btn-outline {
          background:transparent;
          color:var(--fg);
          border:1px solid var(--border-strong);
        }
        .btn-outline:hover { background:var(--card-hover); }

        main { max-width:1750px; margin:0 auto; padding:1.2rem 1.4rem 4rem; }

        .grid-kpi {
          display:grid;
          grid-template-columns:repeat(auto-fit,minmax(170px,1fr));
          gap:.9rem;
          margin-bottom:1.4rem;
        }
        .card {
          background:var(--card);
          border:1px solid var(--border);
          border-radius:var(--radius);
          padding:.85rem .9rem 1rem;
          position:relative;
          box-shadow:var(--shadow);
          display:flex;
          flex-direction:column;
          gap:.4rem;
          transition:.18s background,.18s border-color;
        }
        .card:hover { background:var(--card-hover); }
        .kpi-label {
          font-size:.63rem;
          font-weight:600;
          text-transform:uppercase;
          letter-spacing:.07em;
          color:var(--fg-muted);
        }
        .kpi-value {
          font-size:1.55rem;
          font-weight:600;
          line-height:1.05;
        }
        .kpi-sub {
          font-size:.6rem;
          color:var(--fg-muted);
        }

        .sections {
          display:grid;
          grid-template-columns:repeat(auto-fit,minmax(380px,1fr));
          gap:1rem;
          margin-bottom:1.4rem;
        }
        .section-title {
          margin:0;
          font-size:.9rem;
          font-weight:600;
          display:flex;
          gap:.5rem;
          align-items:center;
        }

        .chips {
          display:flex;
          flex-direction:column;
          gap:.45rem;
          max-height:260px;
          overflow:auto;
          padding-right:.25rem;
        }
        .chip {
          display:flex;
            justify-content:space-between;
          gap:.75rem;
          font-size:.68rem;
          padding:.45rem .65rem;
          background:var(--bg);
          border:1px solid var(--border);
          border-radius:8px;
          line-height:1.1;
        }
        .chip strong { font-weight:600; }

        .accordion .toggle {
          position:absolute;
          top:.7rem; right:.65rem;
          background:transparent;
          border:1px solid var(--border);
          color:var(--fg-muted);
          width:28px; height:26px;
          border-radius:6px;
          display:flex; align-items:center; justify-content:center;
          font-size:.85rem;
          cursor:pointer;
          transition:.18s background;
        }
        .accordion .toggle:hover { background:var(--card-hover); }
        .accordion.collapsed .content { display:none; }

        table {
          width:100%;
          border-collapse:collapse;
          font-size:.7rem;
          border:1px solid var(--border);
          border-radius:10px;
          overflow:hidden;
        }
        thead th {
          background:var(--bg);
          font-weight:600;
          padding:.55rem .55rem;
          text-align:left;
          font-size:.62rem;
          letter-spacing:.06em;
          text-transform:uppercase;
          border-bottom:1px solid var(--border);
          cursor:pointer;
          user-select:none;
        }
        tbody td {
          padding:.5rem .55rem;
          border-top:1px solid var(--border);
        }
        tbody tr:hover { background:var(--card-hover); }

        .toolbar {
          display:flex;
          flex-wrap:wrap;
          gap:.65rem;
          align-items:center;
          margin:0 0 .5rem;
        }
        .search {
          position:relative;
          flex:1;
          min-width:220px;
        }
        .search input {
          width:100%;
          background:var(--card);
          border:1px solid var(--border);
          padding:.55rem .75rem .55rem 2rem;
          border-radius:8px;
          font-size:.7rem;
          transition:.18s border-color;
          color:var(--fg);
        }
        .search input:focus {
          outline:0;
          border-color:var(--accent);
          box-shadow:0 0 0 2px hsl(221 83% 53% / .25);
        }
        .search svg {
          position:absolute;
          top:50%; left:.55rem;
          width:14px; height:14px;
          transform:translateY(-50%);
          stroke:var(--fg-muted);
        }

        .muted { color:var(--fg-muted); font-size:.65rem; }
        .small-gap { gap:.35rem; }

        .show-more {
          align-self:flex-start;
          margin-top:.4rem;
        }

        .footer {
          text-align:center;
          padding:2.5rem 0 1rem;
          font-size:.6rem;
          color:var(--fg-muted);
        }

        /* Ajout styles uPlot */
        .uplot, .uplot * {
          font-family: system-ui,-apple-system,Segoe UI,Roboto,'Inter',sans-serif;
        }
        .uplot {
          background: var(--card);
          border:1px solid var(--border);
          border-radius:8px;
        }
        .uplot-title { font-size:.7rem; }
        .chart-box {
          width:100%;
          height:320px;
          position:relative;
        }
        .legend-tags {
          display:flex;
          flex-wrap:wrap;
          gap:.4rem;
          margin-top:.6rem;
        }
        .legend-tags label {
          display:flex;
          align-items:center;
          gap:.35rem;
          font-size:.6rem;
          background:var(--bg);
          border:1px solid var(--border);
          padding:.25rem .5rem;
          border-radius:6px;
          cursor:pointer;
          user-select:none;
        }
        .legend-tags input { margin:0; }
        .dark .uplot { background:var(--card); }

        .multi-table-grid {
          display:grid;
          gap:.75rem;
          grid-template-columns:repeat(auto-fit,minmax(190px,1fr));
        }
        .multi-table-grid table {
          width:100%;
          font-size:.62rem;
          border:1px solid var(--border);
          border-radius:8px;
          background:var(--card);
        }
        .multi-table-grid thead th {
          background:var(--bg);
          padding:.4rem .45rem;
          font-size:.55rem;
          letter-spacing:.05em;
        }
        .multi-table-grid tbody td {
          padding:.35rem .45rem;
          border-top:1px solid var(--border);
          word-break:break-word;
        }
        .multi-table-grid tbody tr:hover { background:var(--card-hover); }

        @media (max-width:900px){
          .grid-kpi { grid-template-columns:repeat(auto-fit,minmax(150px,1fr)); }
          .sections { grid-template-columns:1fr; }
        }
      </style>
    </head>
    <body>
      <header>
        <h1>📊 Dashboard Support</h1>
        <div class="spacer"></div>
        <button id="themeToggle" class="btn-outline btn" aria-label="Basculer le thème">Thème</button>
      </header>
      <main>

        <!-- KPIs -->
        <section class="grid-kpi">
          <div class="card">
            <div class="kpi-label">Total des tickets</div>
            <div class="kpi-value"><%= total_tickets %></div>
            <div class="kpi-sub">Période: <%= first_date.strftime('%d/%m/%Y') %> – <%= last_date.strftime('%d/%m/%Y') %></div>
          </div>
          <div class="card">
            <div class="kpi-label">Commentaires moyens / ticket</div>
            <div class="kpi-value"><%= average_comments.round(2) %></div>
            <div class="kpi-sub">Total: <%= total_comments %></div>
          </div>
            <div class="card">
            <div class="kpi-label">Longueur moyenne commentaire</div>
            <div class="kpi-value"><%= average_comment_length %></div>
            <div class="kpi-sub">Caractères</div>
          </div>
          <div class="card">
            <div class="kpi-label">Tickets résolus</div>
            <div class="kpi-value"><%= solved_count %></div>
            <div class="kpi-sub"><%= ((solved_count.to_f / (total_tickets.nonzero? || 1))*100).round(1) %>% du total</div>
          </div>
          <div class="card">
            <div class="kpi-label">Commentaires publics</div>
            <div class="kpi-value"><%= public_comments %></div>
            <div class="kpi-sub"><%= ((public_comments.to_f / (total_comments.nonzero? || 1))*100).round(1) %>% des commentaires</div>
          </div>
          <div class="card">
            <div class="kpi-label">Top demandeur (tickets)</div>
            <div class="kpi-value"><%= top_requesters.first&.last || 0 %></div>
            <div class="kpi-sub">ID: <%= top_requesters.first&.first || '—' %></div>
          </div>
        </section>

        <!-- Sections (cartes) -->
        <section class="sections">

          <div class="card accordion" id="acc-descriptions">
            <h2 class="section-title">📝 Top 5 — Longueur description</h2>
            <button class="toggle" data-target="acc-descriptions" aria-label="Basculer la section">−</button>
            <div class="content chips">
              <% top_tickets_by_description.each do |t| %>
                <div class="chip">
                  <span><a href="https://mesvaccinshelp.zendesk.com/agent/tickets/<%= t[:nice_id] %>">#<%= t[:nice_id] %></a></span>
                  <strong><%= t[:description].length %> caractères</strong>
                </div>
              <% end %>
            </div>
          </div>

          <div class="card accordion" id="acc-users">
            <h2 class="section-title">🏆 Top 10 demandeurs</h2>
            <button class="toggle" data-target="acc-users" aria-label="Basculer la section">−</button>
            <div class="content chips">
              <% top_requesters.each do |user_id, count| %>
                <div class="chip">
                  <span><a href="https://mesvaccinshelp.zendesk.com/agent/users/<%= user_id %>">Utilisateur <%= user_id %></a></span>
                  <strong><%= count %></strong>
                </div>
              <% end %>
            </div>
          </div>

          <div class="card accordion" id="acc-staff">
            <h2 class="section-title">👥 Réponses par membre équipe</h2>
            <button class="toggle" data-target="acc-staff" aria-label="Basculer la section">−</button>
            <div class="content chips">
              <% if staff_fetch_error %>
                <div class="chip">
                  <span>Erreur API Zendesk (auth)</span>
                  <strong title="<%= staff_fetch_error %>">!</strong>
                </div>
              <% elsif reponses_par_membre.empty? %>
                <div class="chip">
                  <span>Données indisponibles</span>
                  <strong>—</strong>
                </div>
              <% else %>
                <% reponses_par_membre.each do |name, count| %>
                  <div class="chip">
                    <span><%= name %></span>
                    <strong><%= count %></strong>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>

          <div class="card accordion" id="acc-clusters">
            <h2 class="section-title">🧠 Thèmes des clusters</h2>
            <button class="toggle" data-target="acc-clusters" aria-label="Basculer la section">−</button>
            <div class="content chips">
              <% cluster_topics.sort_by { |cid,_| cid.to_i }.each do |cid, topic| %>
                <div class="chip">
                  <span>Cluster <%= cid %></span>
                  <strong title="<%= topic %>"><%= (cluster_counts[cid.to_s]||0) %></strong>
                </div>
              <% end %>
            </div>
          </div>

        </section>

        <!-- Graphiques -->
        <section class="sections" style="grid-template-columns:repeat(auto-fit,minmax(460px,1fr));">
          <div class="card">
            <h2 class="section-title">📊 Tickets par jour</h2>
            <div id="dailyChart" class="chart-box"></div>
          </div>
          <div class="card">
            <h2 class="section-title">📈 Progression cumulée</h2>
            <div id="cumulativeChart" class="chart-box"></div>
          </div>
          <div class="card" style="grid-column:span 2;">
            <h2 class="section-title">🏷️ Étiquettes par semaine</h2>
            <div id="tagsChart" class="chart-box"></div>
            <div id="tagsLegend" class="legend-tags"></div>
          </div>
        </section>

        <!-- Tableau top tickets (multicolonnes) -->
        <section class="card" id="section-top-tickets">
          <h2 class="section-title">⬆️ Top 100 tickets (commentaires)</h2>

          <div class="toolbar">
            <div class="search">
              <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.35-4.35"/></svg>
              <input id="searchTickets" type="text" placeholder="Filtrer par ID..." aria-label="Filtrer les tickets">
            </div>
            <span class="muted" id="countFiltered"></span>
          </div>

          <div class="multi-table-grid" id="topTicketsWrapper">
            <% global_index = 0 %>
            <% ticket_columns.each_with_index do |col, ci| %>
              <table>
                <thead>
                  <tr><th>ID</th><th>Comm.</th></tr>
                </thead>
                <tbody class="topTicketsBody">
                  <% col.each do |t| %>
                    <tr> <!-- supprimé condition hidden-row -->
                      <td data-id="<%= t[:nice_id] %>"><a href="https://mesvaccinshelp.zendesk.com/agent/tickets/<%= t[:nice_id] %>"><%= t[:nice_id] %></a></td>
                      <td data-comments="<%= t[:comments].size %>"><%= t[:comments].size %></td>
                    </tr>
                    <% global_index += 1 %>
                  <% end %>
                </tbody>
              </table>
            <% end %>
          </div>
          <!-- Bouton "Afficher tout" supprimé -->
        </section>

        <div class="footer">
          Généré automatiquement · <%= Time.now.strftime('%d/%m/%Y %H:%M') %>
        </div>
      </main>

      <script>
        // === Helpers axes / labels / tooltips ===
        function condense(arr, max){
          if (arr.length <= max) return arr.map((v,i)=>({v,show:true}));
          const step = Math.ceil(arr.length / max);
          return arr.map((v,i)=>({v,show: i % step === 0}));
        }
        function formatDay(ts){
          const d = new Date(ts*1000);
          return d.toLocaleDateString('fr-FR',{day:'2-digit',month:'2-digit'});
        }
        function formatFull(ts){
          const d = new Date(ts*1000);
          return d.toLocaleDateString('fr-FR',{day:'2-digit',month:'2-digit',year:'numeric'});
        }
        // Tooltip plugin
        function tooltipPlugin(formatX, formatY){
          let over, box;
          function init(u){
            over = u.root.querySelector('.u-over');
            box = document.createElement('div');
            box.style.cssText = 'position:absolute;pointer-events:none;background:rgba(0,0,0,.72);color:#fff;font-size:11px;padding:4px 6px;border-radius:4px;line-height:1.2;z-index:10;transform:translate(-50%,-110%);white-space:nowrap;';
            u.root.appendChild(box);
            box.hidden = true;
            over.addEventListener('mouseleave', ()=> box.hidden = true);
            over.addEventListener('mousemove', e=>{
              const rect = over.getBoundingClientRect();
              const left = e.clientX - rect.left;
              const top  = e.clientY - rect.top;
              const idx = u.posToIdx(left);
              if (idx < 0 || idx >= u.data[0].length) { box.hidden = true; return; }
              const xVal = u.data[0][idx];
              let html = `<strong>${formatX(xVal)}</strong>`;
              for (let si=1; si<u.series.length; si++){
                const s = u.series[si];
                if (!s.show) continue;
                const y = u.data[si][idx];
                if (y == null) continue;
                html += `<br><span style="color:${s._stroke||s.stroke}">${s.label||'Série'}: ${formatY(y)}</span>`;
              }
              box.innerHTML = html;
              box.style.left = left + 'px';
              box.style.top  = top  + 'px';
              box.hidden = false;
            });
          }
          return { hooks:{ init } };
        }

        // Thème
        const root = document.documentElement;
        const themeBtn = document.getElementById('themeToggle');
        const savedTheme = localStorage.getItem('dashTheme');
        if (savedTheme === 'dark') root.classList.add('dark');
        themeBtn.addEventListener('click', ()=>{
          root.classList.toggle('dark');
          localStorage.setItem('dashTheme', root.classList.contains('dark') ? 'dark' : 'light');
          rebuildCharts(); // re-render pour adapter les couleurs
        });

        // Accordéons
        document.querySelectorAll('.accordion .toggle').forEach(btn=>{
          btn.addEventListener('click', ()=>{
            const id = btn.dataset.target;
            const panel = document.getElementById(id);
            panel.classList.toggle('collapsed');
            btn.textContent = panel.classList.contains('collapsed') ? '+' : '−';
          });
        });

        // Recherche / filtrage
        const searchInput = document.getElementById('searchTickets');
        const tbodyList = Array.from(document.querySelectorAll('.topTicketsBody'));

        function allRows(){
          return tbodyList.flatMap(tb => Array.from(tb.querySelectorAll('tr')));
        }

        function updateFilteredCount(){
          const visible = allRows().filter(r => r.style.display !== 'none').length;
          document.getElementById('countFiltered').textContent = visible + ' affichés';
        }

        searchInput.addEventListener('input', () => {
          const q = searchInput.value.trim().toLowerCase();
          allRows().forEach(tr => {
            const id = tr.querySelector('[data-id]').dataset.id.toString().toLowerCase();
            tr.style.display = id.includes(q) ? '' : 'none';
          });
          updateFilteredCount();
        });
        updateFilteredCount();

        // ====== Données ======
        const dayEpochs = <%= day_epochs.to_json %>;
        const dayCounts  = <%= chart_values.to_json %>;
        const cumulative = <%= cumulative_values.to_json %>;

        // Étiquettes (semaines) -> epochs + labels originaux
        const tagDatasets = <%= datasets.to_json %>;
        const tagLabels   = <%= months.to_json %>;
        const tagEpochs   = <%= tag_epochs.to_json %>;

        // Sécurité longueurs
        const len = Math.min(dayEpochs.length, dayCounts.length, cumulative.length);
        const _dayEpochs = dayEpochs.slice(0,len);
        const _dayCounts = dayCounts.slice(0,len);
        const _cumul     = cumulative.slice(0,len);

        // Palette dynamique
        function palette(){
          return [
            '#2563eb','#db2777','#0891b2','#7c3aed','#16a34a','#ea580c',
            '#d97706','#475569','#0d9488','#9333ea','#ef4444','#3b82f6'
          ];
        }

        // Conteneurs
        let uDaily, uCumul, uTags;

        function chartColors(){
          const dark = root.classList.contains('dark');
            return {
              grid: dark ? '#2d3b46' : '#d9e1ee',
              text: dark ? '#dbe2ea' : '#42505c',
              bg:   'transparent',
              areaCumul: dark ? 'rgba(34,197,94,.18)' : 'rgba(34,197,94,.20)',
              lineCumul: dark ? '#22c55e' : '#15803d'
            };
        }

        // Bar rendering (tickets / jour) - simple custom bars
        function barsPlugin() {
          return {
            hooks: {
              draw: u => {
                const ctx = u.ctx;
                const s = u.series[1];
                if (!s.show) return;
                const scaleX = u.axes[0].scale;
                const scaleY = u.axes[1].scale;

                const dx = (u.bbox.width / (u.data[0].length - 1)) * 0.6;

                ctx.save();
                ctx.fillStyle = 'rgba(59,130,246,.65)';
                const xVals = u.data[0];
                const yVals = u.data[1];
                for (let i=0;i<yVals.length;i++){
                  const x = Math.round(u.valToPos(xVals[i], 'x', true) - dx/2);
                  const y = Math.round(u.valToPos(yVals[i], 'y', true));
                  const y0 = Math.round(u.valToPos(0, 'y', true));
                  ctx.fillRect(x, y, dx, y0 - y);
                }
                ctx.restore();
              }
            }
          }
        }

        function buildDaily(){
          const colors = chartColors();
          const labelMap = condense(_dayEpochs, 12); // max ~12 labels
          return new uPlot({
            width: document.getElementById('dailyChart').clientWidth,
            height: 300,
            scales: { x:{time:true}, y:{auto:true} },
            axes: [
              {
                stroke: colors.text,
                grid:{stroke:colors.grid},
                values:(u, vals)=> vals.map(v=>{
                  // n'afficher que ceux marqués
                  return labelMap.find(o=>o.v===v && o.show) ? formatDay(v) : '';
                })
              },
              { stroke: colors.text, grid:{stroke:colors.grid} }
            ],
            series: [
              {},
              {
                label: "Tickets",
                stroke: 'rgba(59,130,246,1)',
                width: 0,
                fill: 'rgba(59,130,246,.05)',
              }
            ],
            plugins:[barsPlugin(), tooltipPlugin(formatFull, v=>v)]
          }, [_dayEpochs, _dayCounts], document.getElementById('dailyChart'));
        }

        function buildCumul(){
          const colors = chartColors();
          const labelMap = condense(_dayEpochs, 12);
          return new uPlot({
            width: document.getElementById('cumulativeChart').clientWidth,
            height: 300,
            scales: { x:{time:true}, y:{auto:true} },
            axes: [
              {
                stroke: colors.text,
                grid:{stroke:colors.grid},
                values:(u, vals)=> vals.map(v=> labelMap.find(o=>o.v===v && o.show) ? formatDay(v) : '')
              },
              { stroke: colors.text, grid:{stroke:colors.grid} }
            ],
            series: [
              {},
              {
                label:"Cumul",
                stroke: colors.lineCumul,
                fill: colors.areaCumul,
                width:2
              }
            ],
            plugins:[tooltipPlugin(formatFull, v=>v)]
          }, [_dayEpochs, _cumul], document.getElementById('cumulativeChart'));
        }

        function buildTags(){
          const colors = chartColors();
          const pal = palette();

          const baseData = [tagEpochs];
          const series = [{}];
          tagDatasets.forEach((ds, i)=>{
            baseData.push(ds.data);
            series.push({
              label: ds.label || ('Série '+(i+1)),
              stroke: ds.borderColor || pal[i % pal.length],
              width:2,
              spanGaps:true,
              show: i < 6
            });
          });

          const labelMap = condense(tagEpochs, 14);
          const axisValues = (u, vals)=> vals.map(v=>{
            return labelMap.find(o=>o.v===v && o.show) ? formatDay(v) : '';
          });

          const uT = new uPlot({
            width: document.getElementById('tagsChart').clientWidth,
            height:300,
            scales:{ x:{time:true}, y:{auto:true} },
            axes:[
              { stroke:colors.text, grid:{stroke:colors.grid}, values:axisValues },
              { stroke:colors.text, grid:{stroke:colors.grid} }
            ],
            legend:{ show:false }, // on gère notre propre légende
            series: series,
            plugins:[tooltipPlugin(
              ts=>{
                const idx = tagEpochs.indexOf(ts);
                const raw = idx >= 0 ? tagLabels[idx] : '';
                return `${formatFull(ts)}${raw && raw!==formatFull(ts) ? ' · '+raw : ''}`;
              },
              y=> y
            )]
          }, baseData, document.getElementById('tagsChart'));

          // Légende custom
          const legendBox = document.getElementById('tagsLegend');
          legendBox.innerHTML='';
          series.slice(1).forEach((s,i)=>{
            const lbl=document.createElement('label');
            const cb=document.createElement('input');
            cb.type='checkbox';
            cb.checked = s.show !== false;
            cb.addEventListener('change',()=> uT.setSeries(i+1,{show:cb.checked}));
            const sw=document.createElement('span');
            sw.style.cssText='width:10px;height:10px;border-radius:3px;background:'+s.stroke;
            lbl.appendChild(cb); lbl.appendChild(sw);
            lbl.appendChild(document.createTextNode(s.label));
            legendBox.appendChild(lbl);
          });
          return uT;
        }

        function rebuildCharts(){
          // détruire anciens
          [uDaily,uCumul,uTags].forEach(u => u && u.destroy());
          uDaily = buildDaily();
          uCumul = buildCumul();
          uTags  = buildTags();
        }

        // Initial build
        rebuildCharts();

        // Resize handling
        window.addEventListener('resize', ()=>{
          clearTimeout(window.__rT);
          window.__rT = setTimeout(rebuildCharts, 250);
        });
      </script>
    </body>
    </html>
    HTML


    renderer = ERB.new(template)
    html_result = renderer.result(binding)

    FileUtils.mkdir_p(File.dirname(output_path))
    File.write(output_path, html_result)
    puts "✅ Visualisation générée : #{output_path}"
  end
end



if __FILE__ == $0
  require_relative 'xml_handler'
  require_relative 'calculs'
 
  path = "../mesvaccinshelp-20250211/tickets.xml"
  tickets = load_tickets_from_xml(path)

  Visualiser.generate_html_report(tickets, "test_output.html")
end