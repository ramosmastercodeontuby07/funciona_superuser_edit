# script/util/normalize_legacy_customers.rb
# Ejecuta con:
#   rails runner script/util/normalize_legacy_customers.rb
#
# Lee:  db/seed_data/legacy_customers_raw.txt
# Escribe: db/seed_data/legacy_customers.txt
# Formato final por línea:
#   <ID>\t<NOMBRE>\t<MENSUALIDAD|SEMANA|DIA>\t<MM/DD/YYYY>

raw_path = Rails.root.join('db', 'seed_data', 'legacy_customers_raw.txt')
out_path = Rails.root.join('db', 'seed_data', 'legacy_customers.txt')

abort "No existe #{raw_path}. Crea ese archivo y pega las 965 líneas." unless File.exist?(raw_path)

plans = %w[MENSUALIDAD SEMANA DIA]
lines = File.read(raw_path, encoding: 'UTF-8').split(/\r?\n/)
out   = []

lines.each_with_index do |raw, idx|
  line = raw.strip
  next if line.empty?

  # Divide por cualquier espacio/tab
  tokens = line.split(/\s+/)

  id    = tokens.shift
  date  = tokens.pop
  plan_idx = tokens.rindex { |t| plans.include?(t.upcase) }

  if plan_idx.nil?
    warn "[L#{idx+1}] No encuentro plan en: #{raw.inspect} — línea omitida"
    next
  end

  plan = tokens[plan_idx]
  name = (tokens[0...plan_idx] || []).join(' ').strip

  if id.to_s !~ /\A\d+\z/
    warn "[L#{idx+1}] ID inválido: #{id.inspect} — línea omitida"
    next
  end
  if date !~ %r{\A\d{1,2}/\d{1,2}/\d{4}\z}
    warn "[L#{idx+1}] Fecha inválida: #{date.inspect} — línea omitida"
    next
  end
  if name.empty?
    warn "[L#{idx+1}] Nombre vacío — línea omitida"
    next
  end

  out << [id.to_i, name, plan.upcase, date].join("\t")
end

FileUtils.mkdir_p(out_path.dirname)
File.write(out_path, out.join("\n"), mode: 'w', encoding: 'UTF-8')

puts "OK: Generado #{out_path} con #{out.size} líneas tabuladas."
