#include "Set_parameters.hh"

#include <cerrno>
#include <climits>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <string>

namespace {

std::string trim(const std::string &value)
{
    std::string::size_type first = 0;
    std::string::size_type last = value.size();
    while (first < last && std::isspace(static_cast<unsigned char>(value[first]))) {
        ++first;
    }
    while (last > first && std::isspace(static_cast<unsigned char>(value[last - 1]))) {
        --last;
    }
    return value.substr(first, last - first);
}

std::string lower_case(const std::string &value)
{
    std::string lowered(value);
    std::string::size_type index;
    for (index = 0; index < lowered.size(); ++index) {
        lowered[index] = static_cast<char>(
            std::tolower(static_cast<unsigned char>(lowered[index])));
    }
    return lowered;
}

void configuration_error(const std::string &message)
{
    std::fprintf(stderr, "ERROR DE CONFIGURACION POLYCRYSTAL: %s\n", message.c_str());
    std::exit(EXIT_FAILURE);
}

std::string clean_value(const std::string &raw_value)
{
    std::string value = trim(raw_value);
    while (!value.empty() && value[value.size() - 1] == ',') {
        value.erase(value.size() - 1);
        value = trim(value);
    }
    return value;
}

int parse_integer(const std::string &name, const std::string &raw_value)
{
    const std::string value = clean_value(raw_value);
    char *end = 0;
    long parsed;

    if (value.empty()) {
        configuration_error("El parametro " + name + " no tiene valor.");
    }
    errno = 0;
    parsed = std::strtol(value.c_str(), &end, 10);
    if (errno != 0 || end == value.c_str() || *end != '\0' ||
        parsed < INT_MIN || parsed > INT_MAX) {
        configuration_error("El parametro " + name + " no es un entero valido: " + value);
    }
    return static_cast<int>(parsed);
}

double parse_real(const std::string &name, const std::string &raw_value)
{
    std::string value = clean_value(raw_value);
    std::string::size_type index;
    char *end = 0;
    double parsed;

    if (value.empty()) {
        configuration_error("El parametro " + name + " no tiene valor.");
    }
    for (index = 0; index < value.size(); ++index) {
        if (value[index] == 'd' || value[index] == 'D') {
            value[index] = 'e';
        }
    }
    errno = 0;
    parsed = std::strtod(value.c_str(), &end);
    if (errno != 0 || end == value.c_str() || *end != '\0') {
        configuration_error("El parametro " + name + " no es un real valido: " + value);
    }
    return parsed;
}

void assign_parameter(const std::string &raw_name, const std::string &value)
{
    const std::string name = lower_case(trim(raw_name));
    if (name == "ngrains_x") {
        ngrains_x = parse_integer(name, value);
    } else if (name == "ngrains_y") {
        ngrains_y = parse_integer(name, value);
    } else if (name == "ngrains_z") {
        ngrains_z = parse_integer(name, value);
    } else if (name == "x_max") {
        x_max = parse_real(name, value);
    } else if (name == "y_max") {
        y_max = parse_real(name, value);
    } else if (name == "z_max") {
        z_max = parse_real(name, value);
    } else if (name == "stochastic") {
        stochastic = parse_integer(name, value);
    } else if (name == "dm") {
        dm = parse_integer(name, value);
    } else {
        configuration_error("Parametro desconocido: " + raw_name);
    }
}

void read_configuration(const std::string &path)
{
    std::ifstream input(path.c_str());
    std::string line;
    unsigned long line_number = 0;
    bool inside_group = false;
    bool group_found = false;
    bool group_finished = false;

    if (!input) {
        configuration_error("No se pudo abrir " + path + ".");
    }

    while (std::getline(input, line)) {
        std::string::size_type comment;
        std::string::size_type separator;
        std::ostringstream location;
        ++line_number;

        comment = line.find('!');
        if (comment != std::string::npos) {
            line.erase(comment);
        }
        line = trim(line);
        if (line.empty()) {
            continue;
        }

        if (!inside_group) {
            if (line[0] == '&') {
                if (lower_case(trim(line)) != "&polycrystal_config") {
                    configuration_error("Grupo NML desconocido en " + path + ".");
                }
                inside_group = true;
                group_found = true;
                continue;
            }
            if (group_finished) {
                configuration_error("Hay contenido despues del cierre de " + path + ".");
            }
            location << "Contenido fuera del grupo NML en la linea " << line_number << ".";
            configuration_error(location.str());
        }

        if (line == "/") {
            inside_group = false;
            group_finished = true;
            continue;
        }

        separator = line.find('=');
        if (separator == std::string::npos || separator == 0) {
            location << "Asignacion invalida en la linea " << line_number << ".";
            configuration_error(location.str());
        }
        assign_parameter(line.substr(0, separator), line.substr(separator + 1));
    }

    if (!group_found) {
        configuration_error("No se encontro el grupo &POLYCRYSTAL_CONFIG en " + path + ".");
    }
    if (inside_group || !group_finished) {
        configuration_error("Falta '/' al final de " + path + ".");
    }
}

void validate_configuration()
{
    if (ngrains_x < 1 || ngrains_y < 1 || ngrains_z < 1) {
        configuration_error("ngrains_x, ngrains_y y ngrains_z deben ser mayores que cero.");
    }
    if (x_max <= 0.0 || y_max <= 0.0 || z_max <= 0.0) {
        configuration_error("x_max, y_max y z_max deben ser mayores que cero.");
    }
    if (stochastic != 0 && stochastic != 1) {
        configuration_error("stochastic debe ser 0 o 1.");
    }
    if (dm < 1) {
        configuration_error("dm debe ser mayor o igual que 1.");
    }
}

} // namespace

//====================================== SETUP =========================================
void Setup()
{
    const char *environment_path;
    std::string configuration_path;
    std::ifstream default_file;

    // Historical defaults are kept for source builds that do not ship an NML file.
    ngrains_x = 3;
    ngrains_y = 4;
    ngrains_z = 8;
    x_max = 15.0;
    y_max = 15.0;
    z_max = 45.0;
    stochastic = 0;
    dm = 1;

    environment_path = std::getenv("BESLE_POLYCRYSTAL_CONFIG_FILE");
    if (environment_path != 0 && environment_path[0] != '\0') {
        configuration_path = environment_path;
        read_configuration(configuration_path);
    } else {
        configuration_path = "Polycrystal.nml";
        default_file.open(configuration_path.c_str());
        if (default_file) {
            default_file.close();
            read_configuration(configuration_path);
        }
    }

    validate_configuration();
}
