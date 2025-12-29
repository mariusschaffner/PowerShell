function global:tfrun {
    <#
    .SYNOPSIS
    runs terraform init, validate, apply

    .DESCRIPTION
    runs terraform init, validate, apply

    .EXAMPLE
    tfrun

    .COMPONENT

    #>
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $env = "test"
    )

    if ($env -eq "test") {
        terraform init
        Write-Host "---------------------------------"
        terraform validate
        Write-Host "---------------------------------"
        terraform plan -var-file="..\..\globals.tfvars" -var-file="test.tfvars" -out .\plan.tfplan
    } elseif ($env -eq "prod") {
        terraform init
        Write-Host "---------------------------------"
        terraform validate
        Write-Host "---------------------------------"
        terraform plan -var-file="..\..\globals.tfvars" -var-file="prod.tfvars" -out .\plan.tfplan
    }
}
