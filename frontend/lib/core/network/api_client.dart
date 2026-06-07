/// Configuração centralizada de rede para comunicação com o backend Django.
library;

/// URL base do backend Django.
///
/// Em ambiente de desenvolvimento local com emulador Android, o endereço
/// `10.0.2.2` mapeia para o `localhost` do host.  Em um dispositivo físico
/// ou na web, substituir pelo IP da máquina ou pelo domínio de produção.
const String kBaseUrl = 'http://localhost:8000';

/// Cabeçalhos padrão enviados em todas as requisições à API.
const Map<String, String> kDefaultHeaders = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};
