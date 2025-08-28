# frozen_string_literal: true

require 'spec_helper'

describe 'barman::postgres' do
  _, os_facts = on_supported_os.first

  let(:facts) do
    os_facts.merge(
      postgres_key: 'ssh-rsa AAABBB',
    )
  end

  let :pre_condition do
    <<~EOS
      include barman
      include postgresql::server
    EOS
  end

  context 'with default parameters' do
    let(:params) do
      {
        description: 'psql',
        postgres_server_id: 'psql',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it {
      expect(exported_resources).to contain_barman__server('psql').with(
        conninfo: 'user=barman dbname=postgres host=foo.example.com port=5432',
      )
    }
  end

  context 'with conninfo' do
    let(:params) do
      {
        conninfo_options: 'sslcert=postgresql.crt',
        postgres_server_id: 'psql',
      }
    end

    it { is_expected.to compile.with_all_deps }

    it {
      expect(exported_resources).to contain_barman__server('psql').with(
        conninfo: 'user=barman dbname=postgres host=foo.example.com port=5432 sslcert=postgresql.crt',
      )
    }
  end
end
