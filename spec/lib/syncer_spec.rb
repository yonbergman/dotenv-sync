require 'spec_helper'
require 'dotenv/sync'
require 'tempfile'

describe Dotenv::Sync::Syncer do

  UNSORTED = 'spec/support/unsorted.env'
  SORTED = 'spec/support/sorted.env'

  describe 'sort' do
    it 'should sort' do
      tmp = Tempfile.new 'unsorted'
      tmp.write(read(UNSORTED))
      tmp.rewind
      subject.sort(tmp.path)
      expect(tmp.read).to eq read(SORTED)
    end
  end

  describe 'generate-key' do
    it 'should create key' do
      tmp = Tempfile.new
      subject = Dotenv::Sync::Syncer.new(key: tmp.path)
      subject.generate_key
      data = tmp.read()
      expect(data).to_not be_empty
    end
  end

  context 'with_key' do
    let(:key) { Tempfile.new.path }
    let(:encrypted) { Tempfile.new.path }
    let(:secret) { Tempfile.new.path }

    subject do
      Dotenv::Sync::Syncer.new(
                                   key: key,
                                   secret: secret,
                                   encrypted: encrypted
                               ).tap do |s|
        s.generate_key
      end
    end

    it 'should initialize properly' do
      subject
    end

    it 'can encrypt' do
      copy(UNSORTED, secret)
      subject.push
      expect(read(encrypted)).to_not be_empty
    end

    it 'can decrypt' do
      copy(UNSORTED, secret)
      subject.push
      reset(secret)
      subject.pull
      data = read(secret)
      expect(data).to eq read(SORTED)
    end
  end

  def read(file)
    open(file).read
  end

  def copy(from, to)
    open(to, 'w') do |f|
      f.write(open(from).read)
    end
  end

  def reset(file)
    open(file, 'w') {|f| f.write("")}
  end

end