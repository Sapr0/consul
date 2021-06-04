# require 'spec_helper'
#
# describe 'consul::default' do
#   default_attributes['consul']['service_user'] = 'consul'
#   default_attributes['consul']['create_service_user'] = true
#   platform 'ubuntu', '16.04'
#
#   context 'with default service_user' do
#     it 'creates the user without a login shell' do
#       is_expected.to create_user('consul')
#     end
#   end
#
#   context 'with johnny5 service_user' do
#     default_attributes['consul']['service_user'] = 'johnny5'
#
#     it 'creates the requested user' do
#       is_expected.to create_user('johnny5')
#     end
#     it 'does not try to create the default user' do
#       is_expected.to_not create_user('consul')
#     end
#   end
#
#   context 'with root service_user' do
#     default_attributes['consul']['service_user'] = 'root'
#
#     it 'does not try to create the root user' do
#       is_expected.to_not create_user('root')
#     end
#     it 'does not try to create the default user' do
#       is_expected.to_not create_user('consul')
#     end
#   end
#
#   context 'with create_service_user disabled' do
#     default_attributes['consul']['create_service_user'] = false
#
#     it 'does not try to create the user' do
#       is_expected.to_not create_user('consul')
#     end
#   end
#
#   context 'on Windows' do
#     platform 'windows', '2012R2'
#
#     it 'does not try to create the user' do
#       is_expected.to_not create_user('consul')
#     end
#   end
# end
