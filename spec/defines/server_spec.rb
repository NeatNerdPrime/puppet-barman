# frozen_string_literal: true

require 'spec_helper'

describe 'barman::server', type: :define do
  _, os_facts = on_supported_os.first
  let(:facts) { os_facts }

  # Example configuration
  let(:title) { 'server1' }
  let(:params) do
    {
      conninfo: 'user=user1 host=server1 db=db1 pass=pass1 port=5432',
      ssh_command: 'ssh postgres@server1',
    }
  end

  let :pre_condition do
    "class {'barman':}"
  end

  # Compiles template
  it { is_expected.to contain_file('/etc/barman.d/server1.conf').with_content(%r{\[server1\]}) }
  it { is_expected.to contain_file('/etc/barman.d/server1.conf').with_content(%r{conninfo = user=user1}) }
  it { is_expected.to contain_file('/etc/barman.d/server1.conf').with_content(%r{ssh_command = ssh postgres@server1}) }

  # Runs 'barman check' on the new server
  it { is_expected.to contain_exec('barman-check-server1').with_command('barman check server1 || true') }

  # Adds compression settings when asked
  context 'without settings' do
    it { is_expected.to contain_file('/etc/barman.d/server1.conf').with_content(%r{compression = gzip}) }
    it { is_expected.not_to contain_file('/etc/barman.d/server1.conf').with_content(%r{_backup_script}) }
  end
  # Does not add compression settings when not asked

  context 'with settings' do
    let(:params) do
      {
        conninfo: 'user=user1 host=server1 db=db1 pass=pass1 port=5432',
        ssh_command: 'ssh postgres@server1',
        compression: 'bzip2',
        pre_backup_script: 'true',
        post_backup_script: 'true',
        custom_lines: 'thisisastring',
      }
    end

    it { is_expected.to contain_file('/etc/barman.d/server1.conf').with_content(%r{compression = bzip2}) }
    it { is_expected.to contain_file('/etc/barman.d/server1.conf').with_content(%r{pre_backup_script = }) }
    it { is_expected.to contain_file('/etc/barman.d/server1.conf').with_content(%r{post_backup_script = }) }
    it { is_expected.to contain_file('/etc/barman.d/server1.conf').with_content(%r{thisisastring}) }
  end

  # Fails with an invalid name
  context 'with invalid name' do
    let(:title) { 'server!@#%' }

    it { is_expected.to raise_error(Puppet::PreformattedError, %r{match for Barman::ServerName}) }
  end

  context 'with valid name and description' do
    let(:title) { 'foo-bar' }
    let(:params) do
      {
        conninfo: 'user=user1 host=server1 db=db1 pass=pass1 port=5432',
        ssh_command: 'ssh postgres@server1',
        description: 'some description',
        compression: 'bzip2',
      }
    end

    it { is_expected.to contain_file('/etc/barman.d/foo-bar.conf').with_content(%r{compression = bzip2}) }
  end

  # Fails without conninfo and ssh_command
  context 'without conninfo' do
    let(:params) { { ssh_command: 'ssh postgres@server1' } }

    it {
      expect { is_expected.to contain_class('barman::server') }.to raise_error(Puppet::Error, %r{(Must pass |expects a value for parameter ')conninfo})
    }
  end

  context 'without ssh_command' do
    let(:params) { { conninfo: 'user=user1 host=server1 db=db1 pass=pass1 port=5432' } }

    it {
      expect { is_expected.to contain_class('barman::server') }.to raise_error(Puppet::Error, %r{(Must pass |expects a value for parameter ')ssh_command})
    }
  end
end
