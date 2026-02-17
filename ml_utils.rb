# ml_utils.rb

module MlUtils
  module_function

  def transpose(matrix)
    return [] if matrix.empty?
    matrix[0].each_index.map { |j| matrix.map { |row| row[j] } }
  end

  def standard_scale(vectors)
    return [vectors, [], []] if vectors.empty?

    cols = transpose(vectors)
    means = cols.map { |c| c.sum.to_f / c.size }
    stds = cols.map do |c|
      m = c.sum.to_f / c.size
      var = c.sum { |x| (x - m) ** 2 }.to_f / c.size
      s = Math.sqrt(var)
      s.zero? ? 1.0 : s
    end

    scaled = vectors.map do |row|
      row.each_with_index.map { |x, i| (x - means[i]) / stds[i] }
    end

    [scaled, means, stds]
  end

  def euclidean_sq(a, b)
    a.each_with_index.sum { |x, i| (x - b[i]) ** 2 }
  end

  def euclidean(a, b)
    Math.sqrt(euclidean_sq(a, b))
  end

  def cosine(a, b)
    na = Math.sqrt(a.sum { |x| x * x })
    nb = Math.sqrt(b.sum { |x| x * x })
    return 0.0 if na.zero? || nb.zero?
    dot = a.each_with_index.sum { |x, i| x * b[i] }
    dot / (na * nb)
  end

  def kmeans(vectors, k, max_iter: 100, seed: 7)
    raise ArgumentError, 'vectors vide' if vectors.empty?
    raise ArgumentError, 'k invalide' if k < 1 || k > vectors.size

    rng = Random.new(seed)
    centers = vectors.shuffle(random: rng).first(k).map(&:dup)
    labels = Array.new(vectors.size, 0)

    max_iter.times do
      changed = false

      vectors.each_with_index do |v, i|
        best_label = 0
        best_dist = Float::INFINITY
        centers.each_with_index do |c, label|
          d = euclidean_sq(v, c)
          if d < best_dist
            best_dist = d
            best_label = label
          end
        end
        changed ||= labels[i] != best_label
        labels[i] = best_label
      end

      grouped = Array.new(k) { [] }
      labels.each_with_index { |label, i| grouped[label] << vectors[i] }

      new_centers = centers.each_with_index.map do |old_c, label|
        points = grouped[label]
        if points.empty?
          vectors[rng.rand(vectors.size)].dup
        else
          dims = old_c.size
          (0...dims).map do |d|
            points.sum { |p| p[d] }.to_f / points.size
          end
        end
      end

      centers = new_centers
      break unless changed
    end

    inertia = labels.each_with_index.sum do |label, i|
      euclidean_sq(vectors[i], centers[label])
    end.to_f

    { labels: labels, centers: centers, inertia: inertia }
  end

  def silhouette(vectors, labels)
    n = vectors.size
    return 0.0 if n <= 1

    clusters = Hash.new { |h, k| h[k] = [] }
    labels.each_with_index { |label, i| clusters[label] << i }

    scores = (0...n).map do |i|
      own_label = labels[i]
      own = clusters[own_label]

      a = if own.size <= 1
        0.0
      else
        own.reject { |j| j == i }.sum { |j| euclidean(vectors[i], vectors[j]) } / (own.size - 1)
      end

      b_candidates = clusters.reject { |k, _| k == own_label }.values.map do |idxs|
        next nil if idxs.empty?
        idxs.sum { |j| euclidean(vectors[i], vectors[j]) } / idxs.size
      end.compact

      b = b_candidates.min || 0.0
      denom = [a, b].max
      denom.zero? ? 0.0 : ((b - a) / denom)
    end

    scores.sum.to_f / scores.size
  end
end
