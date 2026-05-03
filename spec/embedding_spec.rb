require_relative '../embedding'

RSpec.describe 'embedding text preparation' do
  describe '#prepare_text_for_embedding' do
    it 'ne tronque pas un texte court' do
      text = 'ticket court'
      expect(prepare_text_for_embedding(text, 100)).to eq('ticket court')
    end

    it 'tronque un texte long en gardant debut et fin' do
      text = ('A' * 90) + ('B' * 90)
      prepared = prepare_text_for_embedding(text, 80)

      expect(prepared.length).to eq(80)
      expect(prepared).to include('[TRONQUE]')
      expect(prepared.start_with?('A')).to eq(true)
      expect(prepared.end_with?('B')).to eq(true)
    end
  end
end
