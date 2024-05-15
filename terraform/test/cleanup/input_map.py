import os
import re
from collections import defaultdict

# Directory to start searching from
root_dir = '/Users/jamie/Documents/dev/terraform-aws-org-management/terraform/lacework-deploy/terraform/modules/attack/surface/gcp/modules/osconfig'


def parse_module_usage(file_content):
    """Extract inputs from a single module usage."""
    inputs = {}
    input_matches = re.findall(r'(\w+)\s*=\s*var\.(\w+)', file_content)
    for input_match in input_matches:
        input_key, var_name = input_match
        inputs[input_key] = var_name
    return inputs


def generate_inputs_block(inputs):
    """Generate the Terraform variable inputs block."""
    lines = ['variable "inputs" {', '\ttype = object({']
    for key in inputs:
        # Assuming all inputs to be strings for simplicity; adjust as needed
        line = f'\t\t{key} = string'
        lines.append(line)
    lines.append('\t})')
    lines.append('\tdescription = "inherit variables from the parent"')
    lines.append('}')
    return '\n'.join(lines)


def process_module_files(module_dir, module_name):
    """Process all Terraform files for a single module to generate its inputs variable."""
    inputs = defaultdict(set)
    for subdir, dirs, files in os.walk(module_dir):
        for file in files:
            if file.endswith('.tf'):
                file_path = os.path.join(subdir, file)
                with open(file_path, 'r') as f:
                    content = f.read()
                    module_inputs = parse_module_usage(content)
                    for key, value in module_inputs.items():
                        inputs[key].add(value)

    # Generate the Terraform variable inputs block for the module
    if inputs:
        inputs_block = generate_inputs_block(inputs)
        print(f"Inputs block for module '{module_name}':\n{inputs_block}\n")


def main():
    # Assuming each directory under the root is a separate module
    for module_name in os.listdir(root_dir):
        module_dir = os.path.join(root_dir, module_name)
        if os.path.isdir(module_dir):
            process_module_files(module_dir, module_name)


if __name__ == "__main__":
    main()
