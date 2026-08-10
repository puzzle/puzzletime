# Reconcile the phase-1 @extend -> mixin restructuring.
# Claim under test: the ONLY difference is that selectors our SCSS used to
# @extend into are no longer glued onto Bootstrap's own rule blocks.
# So: strip our app selectors out of the baseline's selector lists; what
# remains must match the current build exactly.


APP = [
  /(\A|[\s>+~])main([:.\[\s>+~]|\z)/, /\.form-action([:.\[\s>+~]|\z)/,
  /\.table-stripedbody/, /\.worktimes/,
  # the @extend targets, as they appear glued into Bootstrap's selector lists
  /\.figures/, /\.date-label/, /\.entry/
]

def app_selector?(sel)
  APP.any? { |a| sel =~ a }
end

def parse(path)
  css = File.read(path, encoding: 'bom|utf-8').gsub(%r{/\*.*?\*/}m, ' ')
  out, ctx, buf, depth = [], [], +'', 0
  css.each_char do |c|
    case c
    when '{'
      depth += 1
      if buf.strip.start_with?('@') && buf !~ /@(font-face|page)/
        ctx.push(buf.strip.squeeze(' ')); buf = +''
      else
        buf << c
      end
    when '}'
      depth -= 1
      if buf.include?('{')
        sel, decl = buf.split('{', 2)
        out << [ctx.join(' | '),
                sel.strip.squeeze(' ').split(',').map(&:strip).reject(&:empty?),
                decl.strip.squeeze(' ').split(';').map(&:strip).reject(&:empty?)]
        buf = +''
      else
        ctx.pop; buf = +''
      end
    else
      buf << (c =~ /\s/ ? ' ' : c)
    end
  end
  out
end

base, cur = parse(ARGV[0]), parse(ARGV[1])

# Bootstrap side of the baseline: drop app selectors from every selector list.
base_bs = base.filter_map do |ctx, sels, decls|
  keep = sels.reject { |s| app_selector?(s) }
  keep.empty? ? nil : [ctx, keep.join(','), decls.join(';')]
end
# App side of the baseline: only the app selectors.
base_app = base.filter_map do |ctx, sels, decls|
  keep = sels.select { |s| app_selector?(s) }
  keep.empty? ? nil : [ctx, keep.join(','), decls]
end

cur_bs = cur.filter_map do |ctx, sels, decls|
  keep = sels.reject { |s| app_selector?(s) }
  keep.empty? ? nil : [ctx, keep.join(','), decls.join(';')]
end
cur_app = cur.filter_map do |ctx, sels, decls|
  keep = sels.select { |s| app_selector?(s) }
  keep.empty? ? nil : [ctx, keep.join(','), decls]
end

def tally(a) = a.tally

puts "=== BOOTSTRAP-SIDE RULES (app selectors stripped from both) ==="
d1 = tally(base_bs).reject { |k, v| tally(cur_bs)[k] == v }
d2 = tally(cur_bs).reject { |k, v| tally(base_bs)[k] == v }
if d1.empty? && d2.empty?
  puts "IDENTICAL — #{base_bs.size} rules. Bootstrap itself is untouched."
else
  puts "DIFFERS (#{d1.size} missing / #{d2.size} extra):"
  d1.first(15).each { |k, _| puts "  - #{k.inspect[0, 260]}" }
  d2.first(15).each { |k, _| puts "  + #{k.inspect[0, 260]}" }
end

puts
puts "=== APP-SIDE: declarations each extended element receives ==="
# Collapse to: selector -> ordered list of declarations (across all its rules)
def per_selector(rules)
  h = Hash.new { |x, k| x[k] = [] }
  rules.each { |ctx, sel, decls| sel.split(',').each { |s| h[[ctx, s]].concat(decls) } }
  h
end
b, c = per_selector(base_app), per_selector(cur_app)
(b.keys | c.keys).sort_by(&:to_s).each do |k|
  bd, cd = (b[k] || []), (c[k] || [])
  # compare as sets of declarations; order only matters for duplicate properties
  lost  = bd - cd
  added = cd - bd
  next if lost.empty? && added.empty?
  puts "#{k[1]}#{k[0].empty? ? '' : "   [#{k[0]}]"}"
  puts "    LOST : #{lost.join('; ')}"   unless lost.empty?
  puts "    ADDED: #{added.join('; ')}"  unless added.empty?
end
puts "(nothing listed above = every extended element keeps the same declarations)"
