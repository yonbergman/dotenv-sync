require 'spec_helper'
require 'dotenv/sync'
require 'tempfile'

describe Dotenv::Sync::Syncer do

  UNSORTED = 'spec/support/unsorted.env'
  SORTED = 'spec/support/sorted.env'
  NEW = 'spec/support/new.env'
  MERGED = 'spec/support/merged.env'
  RESOLVED = 'spec/support/resolved.env'

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
      tmp = Tempfile.new('key')
      subject = Dotenv::Sync::Syncer.new(key: tmp.path)
      subject.generate_key
      data = tmp.read()
      expect(data).to_not be_empty
    end
  end

  context 'with_key' do
    let(:key) { Tempfile.new('key').path }
    let(:encrypted) { Tempfile.new('encrypted').path }
    let(:secret) { Tempfile.new('secret').path }

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

    it 'can merge' do
      copy(NEW, secret)
      subject.push
      copy(SORTED, secret)
      subject.merge
      data = read(secret)
      expect(data).to eq read(MERGED)
    end

    describe 'resolve_conflict' do
      before do
        left = <<-ENV.gsub(/^\s+/, '')
          ###
          # Comment block
          ###
          A=2
          B=3
          TEST=a
        ENV

        right = <<-ENV.gsub(/^\s+/, '')
          A=1
          TEST=b
        ENV

        write(secret, left)
        subject.push
        enc_left = read(encrypted)

        write(secret, right)
        subject.push
        enc_right = read(encrypted)

        conflict = <<-ENV.gsub(/^\s+/, '')
          <<<<<<< branch_a
          #{enc_right.strip}
          =======
          #{enc_left.strip}
          >>>>>>> branch_b
        ENV

        write(encrypted, conflict)
      end

      it 'should resolve conflict in example file' do
        thor = double('thor')
        allow(thor).to receive(:ask).and_return(2)
        allow(thor).to receive(:set_color).with(any_args).and_return('')
        expect(thor).to receive(:say).twice

        subject.resolve_conflict(thor)
        subject.pull

        data = read(secret)
        expect(data).to eq read(RESOLVED).strip

        comments = <<-EOC.gsub(/^\s+/, '')
          ###
          # Comment block
          ###
        EOC

        expect(data).to start_with comments
      end
    end
  end

  def read(file)
    open(file).read
  end

  def write(file, data)
    open(file, 'w') do |f|
      f.write(data)
    end
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
