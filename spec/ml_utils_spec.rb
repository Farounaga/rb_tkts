require_relative '../ml_utils'

RSpec.describe MlUtils do
  describe '.cosine' do
    it 'retourne 1.0 pour deux vecteurs identiques' do
      expect(MlUtils.cosine([1.0, 0.0], [1.0, 0.0])).to eq(1.0)
    end

    it 'retourne 0.0 pour deux vecteurs orthogonaux' do
      expect(MlUtils.cosine([1.0, 0.0], [0.0, 1.0])).to eq(0.0)
    end

    it 'retourne 0.0 si un vecteur est nul (cas limite de robustesse)' do
      expect(MlUtils.cosine([0.0, 0.0], [1.0, 2.0])).to eq(0.0)
    end
  end

  describe '.euclidean' do
    it 'calcule une distance connue (triangle 3-4-5)' do
      expect(MlUtils.euclidean([0.0, 0.0], [3.0, 4.0])).to eq(5.0)
    end
  end

  describe '.standard_scale' do
    it 'centre correctement les colonnes autour de 0' do
      scaled, means, stds = MlUtils.standard_scale([[1.0, 2.0], [3.0, 4.0]])
      col0_sum = scaled.map { |row| row[0] }.sum
      col1_sum = scaled.map { |row| row[1] }.sum

      expect(means).to eq([2.0, 3.0])
      expect(stds.all? { |x| x.positive? }).to eq(true)
      expect(col0_sum.abs).to be < 1e-10
      expect(col1_sum.abs).to be < 1e-10
    end
  end

  describe '.kmeans' do
    it 'lève une erreur quand k > nombre de points (cas limite)' do
      expect { MlUtils.kmeans([[0.0, 0.0], [1.0, 1.0]], 3) }.to raise_error(ArgumentError)
    end
  end
end
