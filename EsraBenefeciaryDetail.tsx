import * as React from 'react';
import styles from './EsraBenefeciaryDetail.module.scss';
import * as strings from 'EsraBenefeciaryDetailWebPartStrings';
import { IEsraBenefeciaryDetailProps,IStipendRequest,IRecordVersion } from './IEsraBenefeciaryDetailProps';
import { IEsraBenefeciaryDetailState } from './IEsraBenefeciaryDetailState';
import { escape } from '@microsoft/sp-lodash-subset';
import { Placeholder } from "@pnp/spfx-controls-react/lib/Placeholder";
import { DisplayMode } from '@microsoft/sp-core-library';
import Paper from '@material-ui/core/Paper';
import Table from '@material-ui/core/Table';
import TableBody from '@material-ui/core/TableBody';
import TableCell from '@material-ui/core/TableCell';
import { Alert, AlertTitle } from '@material-ui/lab';
import TableContainer from '@material-ui/core/TableContainer';
import TableHead from '@material-ui/core/TableHead';
import TableFooter from '@material-ui/core/TableFooter';
import TableRow from '@material-ui/core/TableRow';
import { Grid, InputAdornment, Link, TextField,Checkbox,Radio } from '@material-ui/core';
import SearchIcon from '@material-ui/icons/Search';
import { WebPartTitle } from "@pnp/spfx-controls-react/lib/WebPartTitle";
import { withStyles, Theme, createStyles, makeStyles } from '@material-ui/core/styles';
import TableSortLabel from '@material-ui/core/TableSortLabel';
import { ExportListItemsToCSV } from '../../../Shared/Common/ExportListItemsToCSV/ExportListItemsToCSV';
import { ExportListItemsToPDF } from '../../../Shared/Common/ExportListItemsToPDF/ExportListItemsToPDF';
import { PaginationCustom } from '../../../Shared/Common/Pagination/PaginationCustom';
import * as ESRASPService from 'esra-services'; 
import { Dialog, DialogType, DialogFooter } from 'office-ui-fabric-react/lib/Dialog'; 
import "@pnp/sp/profiles";
import Button from '@material-ui/core/Button'; 
import FileViewer from 'react-file-viewer';
import { DetailsList,TooltipHost,IColumn,DetailsListLayoutMode,SelectionMode,  Overlay,IconButton,Modal,PrimaryButton,Stack, getDatePartHashValue } from '@fluentui/react';
import * as moment from 'moment-timezone';
import Slide from '@material-ui/core/Slide';
import { ThreeSixtySharp } from '@material-ui/icons';
import Backdrop from '@material-ui/core/Backdrop';
import CircularProgress from '@material-ui/core/CircularProgress';
import Snackbar from '@material-ui/core/Snackbar'; 
import {DisplayTermsAndCondition} from 'esra-common-controls'; 

const StyledTableCell = withStyles((theme: Theme) =>
  createStyles({
    head: {
      backgroundColor: 'rgba(255, 255, 255, 1)',
      fontWeight: 600,
      fontFamily: 'Segoe UI',
      padding: '0 10px',
      fontSize: 13,
    },
    body: {
      fontSize: 13,
      padding: '5px 10px',
      fontFamily: 'Segoe UI',
      backgroundColor: 'rgba(255, 255, 255, 1)',
    },
  }),
)(TableCell); 

export default class EsraBenefeciaryDetail extends React.Component<IEsraBenefeciaryDetailProps,IEsraBenefeciaryDetailState, {}> {
  
  private  IsdialogOpen:boolean;
   private _itemId:number=0;
   private _StipendList:string="Stipend Request";
   private _PolicyList:string="Policy Configuration";
   private _ConfigList:string="Application Configuration";
   private _CountryList:string="Countries";
   private _services: ESRASPService.ESRAListOperations = null;
   private _Userservices: ESRASPService.ESRAUserInfo = null;
   private _ADLocationField:string= 'USA' ;
   private _FulltimeEmployeeValues:string= '' ;
   private _ContractEmployeeValues:string= '' ;
   private _AllowedLocations:string= 'USA' ;
   private _CurrUserCountry:string= 'USA' ;
   private ErrorMsg:string= '' ;
   private Erroflg:boolean = false;
   private _currUser:  any;
   private _CurrUserType:string= 'Full Time' ;
   private _CurrUserRole:string= 'Beneficiary' ;
private _PolicyType:string= 'Enrollment' ;
 
   public StipendColumns =[];
   public columnsVersionHistory = [];
   private _VPTitle:  any;
   private _DeviceEnrolmentStepsURL:  any;
  
   private atleastoneitmselected:boolean = false;
   private  FrmStipendAmount:string ='';
   private  FrmStipendCategory:string ='';
   
  
  constructor(props: IEsraBenefeciaryDetailProps,state:IEsraBenefeciaryDetailState) {
    super(props);
    this._services = new ESRASPService.ESRAListOperations(this.props.context.pageContext.web.absoluteUrl);
   this._Userservices = new ESRASPService.ESRAUserInfo(this.props.context.pageContext.web.absoluteUrl);
    let StipendColumns = [
    { 
        key: "Beneficiary", 
        name: "Beneficiary", 
        fieldName: "Beneficiary", 
        minWidth: 120, 
        maxWidth: 120, 
        isResizable: false  ,
        isSorted: false,
        isSortedDescending: false,
        onColumnClick: this._onColumnClick
      },
      { 
        key: "Manager", 
        name: "Manager", 
        fieldName: "Manager", 
        minWidth: 120, 
        maxWidth: 120, 
        isResizable: false,
        isSorted: false,
        isSortedDescending: false,
        onColumnClick: this._onColumnClick
      },     
      { 
        key: "StipendAmount", 
        name: "Stipend Amount", 
        fieldName: "StipendAmount", 
        minWidth: 120, 
        maxWidth: 120, 
        isResizable: false,
        isSorted: false,
        isSortedDescending: false,
        onColumnClick: this._onColumnClick 
      },
      { 
        key: "Status", 
        name: "Request Status", 
        fieldName: "Status", 
        minWidth: 120, 
        maxWidth:120, 
        isResizable: false,
        isSorted: false,
        isSortedDescending: false,
        onColumnClick: this._onColumnClick 
      },
      { 
        key: "RequestDate", 
        name: "Request Date & Time", 
        fieldName: "RequestDate", 
        minWidth: 150, 
        maxWidth: 150, 
        isResizable: false 
      },
      { 
        key: "id", 
        name: "History", 
        fieldName: "id", 
        minWidth: 100,
        maxWidth: 100,
        onRender: (StipendItem: []) => (
            <div>
              <TooltipHost content="Version History">
                <IconButton iconProps={{iconName:"History"}}  ariaLabel="showHistory" onClick={() => this._onVersionClick(StipendItem)} />
              </TooltipHost>
            </div>
            ),
      }
    ];

    this.state = {
      listItems: [],
      columns: [],
      page: 0,
      rowsPerPage: Number(this.props.pageSize),
      searchText: '',
      sortingFields: '',
      sortDirection: 'asc',
      contentType: '',
      isAllSelected:false, 
      TNCchkbxVal:false,
      HideSubmitDialogMsg:true,
      Beneficiary: '',
      BeneficiaryId: 0,
      BeneficiaryType: '',
      BeneficiaryJobGrade: '',
      BeneficiaryDepartment: '',
      BeneficiaryHomeCountry: '',
      BeneficiaryHomeCountryId:0,
      BeneficiaryCurrentCountry: '',
      BeneficiaryCurrentCountryId:0,
      StipendAmount: '',
      StipendCategory:'',
      AgreementAccepted: false,
      RequestDate:'',
      RequestType: '',
      Requester: '',
      RequesterId: '',
      Status: '',
    
      ApprovalRejectDate: '',
      Manager: '',
      ManagerId: '',
      Reviewer: '',
      ReviewerId: '',
      PolicyDocumentUrl: '', 
      EnrollBtnDisbled:true,
      StipendItem:[],
      Stipendcolumns:StipendColumns,  
      ShowVersionHistory:false,
      ItemChanges:[],
      PolicyfilePath:'',
      PolicyfileName:'',
      IsUpdatemode:false,
      ShowEnrollmentform:false,
      ShowStipendinfo:false, 
      toggleIsOverlayVisible:false,
      PageLoaderOpen:true,
      ErrorMsgtype:'',  
      ContractEmployee:false,
      tncfilepath:'',
      openPopUp:false,
    };
// get values from config files
 
try
{
        let configqry:string ="Key eq 'DeviceEnrolmentSteps' or Key eq 'VPTitle' or Key eq 'ADUserLocation' or Key eq 'AllowedLocations' or  Key eq 'ContractEmployeeValues'";
        this._services.geItemByFliter(this._ConfigList,configqry).then(itms =>{
           itms.forEach(elem =>{
        if(elem.Key === "ADUserLocation")
        {
          this._ADLocationField = elem.Value ;
        }
        if(elem.Key === "AllowedLocations")
        {
          this._AllowedLocations = elem.Value ;
        }
        if(elem.Key === "ContractEmployeeValues")
        {
          this._ContractEmployeeValues = elem.Value ;
        }
        if(elem.Key === "VPTitle")
        {
          this._VPTitle = elem.Value ;
        }
        if(elem.Key === "DeviceEnrolmentSteps")
        {
          this._DeviceEnrolmentStepsURL = elem.Value ;
        }
        });

          
          this._services.getCurrentUser().then(usr =>{
            this._currUser = usr;
            this._services.getUserProperties(usr.LoginName).then(UsrProps =>{
            this._CurrUserCountry = this.getUserPropertiesValue(this._ADLocationField,UsrProps);
            if(this._AllowedLocations.indexOf( this._CurrUserCountry) >=0)
            {
                this._onConfigure = this._onConfigure.bind(this);
                this.getSelectedListItems = this.getSelectedListItems.bind(this);
                this._showDialog = this._showDialog.bind(this);
                this._closeDialog = this._closeDialog.bind(this);
                this._SubmitAgree = this._SubmitAgree.bind(this);
                this._SubmitAgree = this._SubmitAgree.bind(this);
                this.TNCCheck = this.TNCCheck.bind(this);
                this.getStipendRecords = this.getStipendRecords.bind(this);
                this.getRecordChanges=this.getRecordChanges.bind(this);
                this._onVersionClick=this._onVersionClick.bind(this); 
                this.handleIsOverlayVisible=this.handleIsOverlayVisible.bind(this);

                // check if record already exists
                let stpchkqry:string ="BeneficiaryId eq '" + this._currUser.Id +"' and  ( RequestType eq 'Enroll' or RequestType eq 'Update') and (Status eq 'Approved' or Status eq 'In Progress' or Status eq 'Pre-Approved') ";
                try
                {
                  this._services.geItemByFliter(this._StipendList,stpchkqry).then(totalitem =>{
                      if(totalitem.length >0)
                      {
                        this._itemId=totalitem[0].Id;
                        this.getStipendRecords();
                      }
                      else
                      {                  
                        this.setBenefeciaryDefaultValues();
                      }
                    });
              }
              catch (error) {
                console.log(error);
                throw error;
              }
           }
          else
          {
            this.ErrorMsg = 'Current user is not from ' + this._AllowedLocations;
            this.setState({toggleIsOverlayVisible:true});
          }
            });
          });           
      });

    }
    catch (error) {
      console.log(error);
      throw error;
        }
    }  


  ////////////////////
  private _onColumnClick = (ev: React.MouseEvent<HTMLElement>, column: IColumn): void => {
    const { Stipendcolumns, StipendItem } = this.state;
    const newColumns: IColumn[] = Stipendcolumns.slice();
    const currColumn: IColumn = newColumns.filter(currCol => column.key === currCol.key)[0];
    newColumns.forEach((newCol: IColumn) => {
      if (newCol === currColumn) {
        currColumn.isSortedDescending = !currColumn.isSortedDescending;
        currColumn.isSorted = true;
        
      } else {
        newCol.isSorted = false;
        newCol.isSortedDescending = true;
      }
    });
    const newItems = this._copyAndSort(StipendItem, currColumn.fieldName!, currColumn.isSortedDescending);
    this.setState({
      Stipendcolumns: newColumns,
      StipendItem: newItems,
    });
}


public _copyAndSort<T>(items: T[], columnKey: string, isSortedDescending?: boolean): T[] {
  const key = columnKey as keyof T;
  return items.slice(0).sort((a: T, b: T) => ((isSortedDescending ? a[key] < b[key] : a[key] > b[key]) ? 1 : -1));
}

private _onVersionClick(item:any){
  console.log(item);
  this.getRecordChanges(item.id);
  
}


  public   getUserPropertiesValue(Propertyname:string,Userprop:any): any{
    try{
let propval :string ="";
        var userProperties = Userprop.UserProfileProperties;  
        var userPropertyValues = "";  
        userProperties.forEach(function(property) {  
        
            if(property.Key === Propertyname)
            {
                propval =  property.Value;
            }  
        });  
        
          return propval;       
        
    } catch (error) {
        console.log(error);
        throw error;
    }
  } 

  public async setBenefeciaryDefaultValues()
  {
    try
    {
      this._services.getCurrentUser().then(usr =>{ 
        this._services.geItemByFliter(this._CountryList,"Title eq '"+ this._CurrUserCountry +"'").then(countryitm=>{
            let countryid = countryitm[0].Id;
            try
            {          
            this._services.getUserProperties(usr.LoginName).then(UsrProps =>{
              let jobtitle:string= this.getUserPropertiesValue('SPS-JobTitle',UsrProps); //get job title. this may be chnaged after getting corrct field for empoyee type
              if(this._ContractEmployeeValues.indexOf(jobtitle)>=0)
              {
                    this.setState({BeneficiaryType: 'Contractor',ContractEmployee:true }); 
              }
              else
              {                  
                this.setState({ BeneficiaryType: 'Fulltime' ,ContractEmployee:false});                    
              }
                this.setState({ 
                  Beneficiary: usr,
                  BeneficiaryId:usr.Id,             
                  BeneficiaryHomeCountry:   this._CurrUserCountry,
                  BeneficiaryHomeCountryId: countryid,
                  BeneficiaryCurrentCountry:  this._CurrUserCountry,
                  BeneficiaryCurrentCountryId: countryid,
                  RequestDate:Date.toString(),
                  RequestType: 'Enroll',
                  Requester: usr,
                  RequesterId: usr.Id,              
                  Status: 'In Progress',
                  AgreementAccepted: false, 
                  BeneficiaryJobGrade: this.getUserPropertiesValue('SPS-JobTitle',UsrProps),
                  BeneficiaryDepartment:this.getUserPropertiesValue('Department',UsrProps),
                  Manager:this.getUserPropertiesValue('Manager',UsrProps), 
                  Reviewer: this.getUserPropertiesValue('Manager',UsrProps)
                }); 

                let iscurrentuserIsVP =this.getUserPropertiesValue('Title',UsrProps);
                if(iscurrentuserIsVP === this._VPTitle)
                {
                  this.setState({ Status: 'Pre-Approved'});
                  
                }

                try
                {
                    this._services.getCurrentUserByLoginName(this.getUserPropertiesValue('Manager',UsrProps)).then(mngr =>{
                    this.setState({ManagerId:mngr.data.Id, ReviewerId:mngr.data.Id }); 
                     let policyqry :string ="Country/Title eq '" + this._CurrUserCountry + "' and Role eq '" + this._CurrUserRole + "' and Active eq 1 and PolicyType eq '"+ this._PolicyType +"'";
                      try
                      { 
                        this._services.geItemByFliter(this._PolicyList,policyqry).then(policyfiles =>{
                        this.setState({PageLoaderOpen:false,ShowEnrollmentform:true});
                              this.setState({ 
                              PolicyfilePath:policyfiles[0].PolicyDocumentUrl.Url,
                              PolicyfileName:policyfiles[0].PolicyDocumentUrl.Description
                              });  
                        });
                      }
                      catch (err)
                      {
                        console.log(err);
                      }
                    });
                }
                catch(error) {
                  console.log(error);
                }

            }); 
          }
          catch(error) {
            console.log(error);
          }
        });
      });    
    }
    catch(error) {
      console.log(error);
    }
  }

  public componentDidMount() {
    this.getSelectedListItems();
  }
 
  public componentDidUpdate(prevProps: IEsraBenefeciaryDetailProps) {
    if (prevProps.list !== this.props.list) {
      this.props.onChangeProperty("list");
    }
    else if (this.props.fields != prevProps.fields) {
      this.getSelectedListItems();
    }
  }
   
  
  public async getSelectedListItems() {
    try
    {
      let fields = this.props.fields || [];
      if (fields.length) {
      this._services.getAllDataForSelectedFields(this.props.list, fields,this.props.filterCondition).then(listItems =>{
        /** Format list items for data grid */
        listItems = listItems && listItems.map(item => ({
          id: item.Id,isItemSelected: false, ...fields.reduce((ob, f) => {
            ob[f.key] = item[f.key] ? this.formatColumnValue(item[f.key], f.fieldType) : '-';
            return ob;
          }, {})
        }));
      // let dataGridColumns = [...fields].map(f => ({ field: f.key as string, headerName: f.text }));
        let dataGridColumns = [{ field: "StipendCategory", headerName: "Category" },
          { field: "StipendDescription", headerName: "Description" }, 
          { field: "MonthlyAmount", headerName: "Stipend Amount" } ];
        
        this.setState({ listItems: listItems, columns: dataGridColumns });
      });
        }
    }
    catch(err)
    {
      console.log(err);
    }
  }

  private _onConfigure() {
    this.props.context.propertyPane.open();
  }

  public formatColumnValue(value: any, type: string) {
    if (!value) {
      return value;
    }
    switch (type) {
      case 'SP.FieldDateTime':
        var strDate = value;
        var strDateParts = strDate.split("T")[0].split("-");
        var formatedDate = strDateParts[1]+"/"+strDateParts[2]+"/"+strDateParts[0];
        value = formatedDate;
        break;
      case 'SP.FieldMultiChoice':
        value = (value instanceof Array) ? value.join() : value;
        break;
      case 'SP.Taxonomy.TaxonomyField':
        value = value['Label'];
        break;
      case 'SP.FieldLookup':
        value = value['Title'];
        break;
      case 'SP.FieldUser':
        value = value['Title'];
        break;
      case 'SP.FieldMultiLineText':
        value = <div dangerouslySetInnerHTML={{ __html: value }}></div>;
        break;
      case 'SP.FieldText':
        value = value;
        break;
      case 'SP.FieldComputed':
        value = value;
        break;
      case 'SP.FieldUrl':
        value = <Link href={value['Url']} target="_blank">{value['Description']}</Link>;
        break;
      case 'SP.FieldLocation':
        value = JSON.parse(value).DisplayName;
        break;
      default:
        break;
    }
    return value;
  }

  private handlePaginationChange(pageNo: number, pageSize: number) {
    this.setState({ page: pageNo, rowsPerPage: pageSize });
  }

  public handleSearch(event: React.ChangeEvent<HTMLInputElement>) {
    this.setState({ searchText: event.target.value });
  }

  public filterListItems() {
    let { searchBy, enableSorting } = this.props;
    let { sortingFields, listItems, searchText } = this.state;
    if (searchText) {
      if (searchBy) {
        listItems = listItems && listItems.length && listItems.filter(l => searchBy.some(field => {
          return (l[field] && l[field].toString().toLowerCase().includes(searchText.toLowerCase()));
        }));
      }
    }
    if (enableSorting && sortingFields) {
      listItems = this.sortListItems(listItems);
    }
    return listItems;
  }

  private sortListItems(listItems: any[]) {
    const { sortingFields, sortDirection } = this.state;
    const isAsc = sortDirection === 'asc' ? 1 : -1;
    let sortFieldDetails = this.props.fields.filter(f => f.key === sortingFields)[0];
    let sortFn: (a, b) => number;
    switch (sortFieldDetails.fieldType) {
      case 'SP.FieldDateTime':
        sortFn = (a, b) => ((new Date(a[sortingFields]).getTime() > new Date(b[sortingFields]).getTime()) ? 1 : -1) * isAsc;
        break;
      default:
        sortFn = (a, b) => ((a[sortingFields] > b[sortingFields]) ? 1 : -1) * isAsc;
        break;
    }
    listItems.sort(sortFn);
    return listItems;
  }

  private paginateFn = (filterItem: any[]) => {
    let { rowsPerPage, page } = this.state;
    return (rowsPerPage > 0
      ? filterItem.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
      : filterItem
    );
  }

  private handleSorting = (property: string) => (event: React.MouseEvent<unknown>) => {
    let { sortingFields, sortDirection } = this.state;
    const isAsc = sortingFields === property && sortDirection === 'asc';
    this.setState({ sortDirection: (isAsc ? 'desc' : 'asc'), sortingFields: property });
  }
  
  private selectAllItems = (event:any) => {
    var getAllItems = this.state.listItems;
    var updatedItems = [];
    if(event.target.checked)
    {
      getAllItems.map(item => {
        item.isItemSelected = true;
        updatedItems.push(item);
      });
      this.setState({listItems:updatedItems,isAllSelected:true});
    }else{
      getAllItems.map(item => {
        item.isItemSelected = false;
        updatedItems.push(item);
      });
      this.setState({listItems:updatedItems,isAllSelected:false});
    }
    console.log(getAllItems);
  }

  private selectItem = (itemVal:any,event:any) => {
    var getAllItems = this.state.listItems;
    var updatedItems = [];
    var isAllSelectedItems= false;
     getAllItems.map(item => {
        if(itemVal.id == item.id)
        {
          item.isItemSelected = true;
        }
        else
        {
          item.isItemSelected = false;
        }
        updatedItems.push(item);
    });


      updatedItems.map(item => {
        if(item.isItemSelected == false)
        {
          isAllSelectedItems = false;
        }
      });
      this.setState({listItems:updatedItems,isAllSelected:isAllSelectedItems});
  }
  
  private RequestEnrolledClick()
  {
            this.Erroflg = false;
            this.ErrorMsg="";
        try
        {
              this.state.listItems.forEach(element => {
                  if(element.isItemSelected)
                  {
                    this.atleastoneitmselected=true;
                    this.FrmStipendAmount=element.MonthlyAmount;
                      this.FrmStipendCategory=element.StipendCategory; 
                    }
              });

              if(!this.state.ContractEmployee ){
              if(!this.atleastoneitmselected)
              {
                this.Erroflg = true;
                this.ErrorMsg = this.ErrorMsg + "Please select a category";
              }}


              if(!this.state.TNCchkbxVal)
              {
                this.Erroflg = true;
                this.ErrorMsg = this.ErrorMsg + "Please agree for terms & condition";
              }
              if(! this.Erroflg )
              {
                  var d = new Date();
                  let currdate:any = d.toISOString();
                  this.setState({HideSubmitDialogMsg:false});
                  let  StipendData : any = {
                      BeneficiaryId  : this.state.BeneficiaryId,
                      BeneficiaryType  :this.state.BeneficiaryType,
                      BeneficiaryJobGrade :this.state.BeneficiaryJobGrade,
                      BeneficiaryDepartment  :this.state.BeneficiaryDepartment,
                      BeneficiaryHomeCountryId:this.state.BeneficiaryHomeCountryId,
                      BeneficiaryCurrentCountryId:this.state.BeneficiaryCurrentCountryId,
                      AgreementAccepted:this.state.AgreementAccepted,
                      StipendCategory  :this.FrmStipendCategory,
                      StipendAmount  :this.FrmStipendAmount,
                      RequestType  :this.state.RequestType,    
                      Status  :this.state.Status,  
                      ManagerId:this.state.ManagerId,    
                      RequestDate: currdate,
                      PolicyDocumentUrl : this.state.PolicyfilePath,
                      PolicyName : this.state.PolicyfileName,
                    };

                    if(this.state.RequesterId != this.state.BeneficiaryId)
                    {
                        StipendData['RequesterId'] =  this.state.RequesterId;
                    }
                    else   
                    {
                      if(this.state.Status === "Pre-Approved"  )// in case auto aporved add app/reject date and reviewr as requester
                        {
                          StipendData['ReviewerId'] =  this.state.RequesterId;
                          StipendData['ApprovalRejectDate'] = currdate;
                        }
                       else
                       {
                        StipendData['ReviewerId'] =  this.state.ReviewerId;
                    }
                  }


                    this._services.createItem(this._StipendList,StipendData).then(result =>{
                      this._itemId = result; 
                      this.setState({HideSubmitDialogMsg:true});
                      this.getStipendRecords();
                    });
              }
              else
              {
                  this.setState({toggleIsOverlayVisible:true,ErrorMsgtype:"error"});           
              }
          
          }
          catch(error) {
            console.log(error);
          }
  }
 
 
public _showDialog()  { 
        this.setState({ openPopUp: true });   
}
 
public _closeDialog () {  
   this.setState({ openPopUp: false });  
}   

 public TNCCheck () {  
    if(this.state.TNCchkbxVal)
    {
       this.setState({  TNCchkbxVal:false,AgreementAccepted: false,EnrollBtnDisbled:true});   
    }
    else
    {
        this.setState({  TNCchkbxVal:true,AgreementAccepted: true,EnrollBtnDisbled:false});   
    }
} 

private _SubmitAgree(){  
 //this.UpdateStatus(sts);
 this.setState({ openPopUp: false, TNCchkbxVal:true,AgreementAccepted: true,EnrollBtnDisbled:false});   
 
} 

 
/////////////////////
//////////
//////////////////

private formatStipendAmount(StipendCat:string,StipendAmnt:string)
{

  if(StipendAmnt === "")
  {
    return StipendCat + " " + StipendAmnt ;
  }
  else
  {
    return StipendCat + " (" + StipendAmnt + ")";
  }
}

private getStipendRecords(){
  try{
    //this._services.getItemByID(this._StipendList,this._itemId).then((item: any) => {
      let seletedfields:any=['ID','StipendAmount','Beneficiary','Manager','Status','StipendCategory','RequestDate'];
      var fields=[{key:"ID",fieldType:""},{key:"Status",fieldType:""},{key:"StipendCategory",fieldType:""},{key:"RequestDate",fieldType:""},{key:"StipendAmount",fieldType:""},{key:"Beneficiary",fieldType:"SP.FieldLookup"},{key:"Manager",fieldType:"SP.FieldLookup"}];
      let selectcondition:string = "ID eq " + this._itemId;
      this._services.getAllDataForSelectedFieldsByListTitle(this._StipendList,fields,selectcondition).then((item: any) => {
      let contentItems:IStipendRequest[]= [];
        if(item.length>0)
        {
            let contentItem={           
              id: item[0].ID,
              StipendAmount : this.formatStipendAmount(this.handleNullString(item[0].StipendCategory),this.handleNullString(item[0].StipendAmount)),
              Status :item[0].Status,
              RequestDate :moment(item[0].RequestDate).format('DD/MM/yyyy hh:mm A'),  
              Manager  :item[0].Manager.Title,
              Beneficiary  :item[0].Beneficiary.Title,      
            };
            contentItems.push(contentItem);          
        }
        this.setState({StipendItem:contentItems,ShowEnrollmentform:false, ShowStipendinfo:true,IsUpdatemode:true});  
        this.setState({PageLoaderOpen:false});
      });
  }catch (error) {
    console.log(error);
  }
}
private getRecordChanges(itemId:number){
  try{
      this._services.getItemVersions(this._StipendList,this._itemId)
      .then((item: any) => {
        console.log(item);
        let contentItems:IRecordVersion[]= [];
        if(item.Versions.length >0)
        {
          item.Versions.map((value,key)=>{
              let contentItem={
                id:value.ID,                
                Requestor : value.Status,
                RequestorType: value.Status,
                DateRequested: value.Status,
                Status: value.Status,
                Manager: value.Status,
                ApprovalRejectDate: value.Status,
                PolicyNumber: value.Status,
                Category: value.Status,
                StipendAmount:value.Status,
                Comments:value.Status,
              };
              contentItems.push(contentItem);
            });
          
        }
        console.log(contentItems);
        this.setState({ItemChanges:contentItems,ShowVersionHistory:true});
      });
  }catch (error) {
    console.log(error);
  }
}

 
private _SubmitCancel(){  
 
  //this.UpdateStatus(sts); 
 } 

 
private _SubmitUpdate(){  
 
  //this.UpdateStatus(sts); 
 } 

private handleIsOverlayVisible()
{
  this.setState({toggleIsOverlayVisible:false});

}
  
private handleNullString(myVar:string)
{
    if( typeof myVar === 'undefined' || myVar === null ){
      return "";
    }
    else
    {
      return myVar;
    }
} 


private _OpenEnrollmentsteps()
{
 // _DeviceEnrolmentStepsURL

 window.open(this._DeviceEnrolmentStepsURL, "_blank");
}




  public render(): React.ReactElement<IEsraBenefeciaryDetailProps> {
    let filteredItems = this.filterListItems();
    let { list, fields, enableDownloadAsCsv, enableDownloadAsPdf, enablePagination, displayMode, enableSearching, title, evenRowColor, oddRowColor, sortBy, enableMultiselectBtnOnLeft } = this.props;
    let { sortingFields, sortDirection, columns, listItems, isAllSelected } = this.state;
    filteredItems = enablePagination ? this.paginateFn(filteredItems) : filteredItems;  
    return (
      <div>

<div>
 
 {this.state.IsUpdatemode && 
<div>
<label  onClick={this._OpenEnrollmentsteps.bind(this)} className={styles.lableHyperlink}>
  Click here for Device Enrolment steps</label> 

</div>
  }
</div>




{this.state.ShowEnrollmentform && 
<div>

<div>
          
<Dialog  
          hidden={this.state.HideSubmitDialogMsg}  
           dialogContentProps={{  
            type: DialogType.close,  
            title: `Submitting data...` ,  
              showCloseButton:false  ,
          }} 
         
          modalProps={{  
            isBlocking: true,  
            styles: { main: { maxWidth: 450 } },  
          }}  
            >   
          <div>
          <CircularProgress />
          </div>
        </Dialog>   
</div>
<div>


{!this.state.ContractEmployee && 
      <div className={styles.reactDatatable}>
        {
          this.props.list == "" || this.props.list == undefined ?
          <Placeholder
          iconName='Edit'
          iconText='Configure your web part'
          description={strings.ConfigureWebpartDescription}
          buttonLabel={strings.ConfigureWebpartButtonLabel}
          hideButton={displayMode === DisplayMode.Read}
          onConfigure={this._onConfigure} /> : <>
          <WebPartTitle className={styles.stipendTableHeader}
            title={title}
            displayMode={DisplayMode.Read}
            updateProperty={() => { }}>
              </WebPartTitle>
              { list && fields && fields.length ?
                <div>
                  <Grid container className={styles.dataTableUtilities}>
                    <Grid item xs={6} className={styles.downloadButtons}>
                      {
                        enableDownloadAsCsv
                          ? <ExportListItemsToCSV
                            columnHeader={columns.map(c => c.headerName)}
                            listName={list}
                            description={title}
                            listItems={listItems}
                          /> : <></>
                      }
                      {
                        enableDownloadAsPdf
                          ? <ExportListItemsToPDF
                            listName={list}
                            htmlElementForPDF='#dataTable'
                          />
                          : <></>
                      }
                    </Grid>
                    <Grid container justify='flex-end' xs={6}>
                      {
                        enableSearching ?
                          <TextField
                            onChange={this.handleSearch.bind(this)}
                            size="small"
                            label="Search"
                            variant="outlined"
                            InputProps={{
                              endAdornment: (
                                <InputAdornment position="end">
                                  <SearchIcon />
                                </InputAdornment>
                              ),
                            }}
                          />
                          : <></>
                      }
                    </Grid>
                  </Grid>
                  <div id="generateTable">
                  <TableContainer component={Paper} className={styles.mainTableContainer}>
                      <Table aria-label="customized table" id="dataTable" >
                        <TableHead>
                          <TableRow>
                            {enableMultiselectBtnOnLeft &&
                              <StyledTableCell >
                                  <label>Choose</label>
                              </StyledTableCell>
                            }
                            {columns.map((c) => (
                              <StyledTableCell key={c.headerName}>
                                {
                                  (sortBy && sortBy.indexOf(c.field) !== -1)
                                    ? <TableSortLabel
                                      active={sortingFields === c.field}
                                      direction={sortingFields === c.field ? sortDirection : 'asc'}
                                      onClick={this.handleSorting(c.field)}
                                    >
                                      {c.headerName}
                                    </TableSortLabel>
                                    : c.headerName
                                }
                              </StyledTableCell>
                            ))}
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {filteredItems.map((row, index) => (
                            <TableRow
                              style={{ backgroundColor: ((index + 1) % 2 === 0) ? evenRowColor : oddRowColor }} >
                              {enableMultiselectBtnOnLeft && 
                              <StyledTableCell > 
                                  <Radio  checked={row.isItemSelected}
        onChange={this.selectItem.bind(this,row)}       name="radio-button-demo"
        inputProps={{ 'aria-label': 'A' }}
      />

                              </StyledTableCell>
                              }
                              {columns.map((c) => (
                                <StyledTableCell >{row[c.field]}</StyledTableCell>
                              ))}
                            </TableRow>
                          ))}
                        </TableBody>
                        {enablePagination ?
                          <React.Fragment>
                            <TableFooter>
                              <TableRow>
                                <PaginationCustom
                                  colSpan={columns.length}
                                  onPaginationUpdate={this.handlePaginationChange.bind(this)}
                                  totalItems={listItems.length}
                                  pageSize={this.props.pageSize} />
                              </TableRow>
                            </TableFooter>
                          </React.Fragment> : <></>
                        }
                      </Table>
                    </TableContainer>
                  </div>
                </div> : <Alert severity="info">
                  {strings.ListFieldValidation}</Alert>
              }</>
        }
      </div >
}

      <div>

      <div className={styles.termsConditions}>
        <h4>Terms & Conditions</h4>
        {this.state.TNCchkbxVal && (
        <Checkbox id='chkbxTNC'  required={true} color="primary" size="small" inputProps={{ 'aria-label': 'primary checkbox' }}  checked={this.state.TNCchkbxVal} onChange={this.TNCCheck} ></Checkbox>
    )}
        <label onClick={this._showDialog} className={styles.lableHyperlink}>Click here to read and agree the Gilead Stipend Terms & Conditions</label>  
      
        {this.state.openPopUp && 
          <DisplayTermsAndCondition
                    fileType="pdf"
                    onApprovalClick={this._SubmitAgree.bind(this)}
                    onCloseClick={this._closeDialog.bind(this)}  
                    filePath={this.state.PolicyfilePath}
                    showModel={this.state.openPopUp}
                    btnName="Agree"
                    headerTitle="Read and Agree Terms & Conditions"
                />}
    </div>
      </div>
      <div className={styles.redButton}>
        <Button disabled={this.state.EnrollBtnDisbled} onClick={() => { this.RequestEnrolledClick();}}>Request Enrollment</Button>
      </div>
       
       
      </div>
 
 
 
 </div>
  }
  
{this.state.ShowStipendinfo && 

<div id="StipendDetails">
<div className={ styles.versionHistoryView }>
<DetailsList
              items={this.state.StipendItem}
              compact={true}
              columns={this.state.Stipendcolumns}
              selectionMode={SelectionMode.none}
              setKey="set"
              layoutMode={DetailsListLayoutMode.justified}
              isHeaderVisible={true}
            />      
   </div>
<div className={styles.CancelUpdateBtns}>       
      <Button className={styles.CancelButton} onClick={this._SubmitCancel}>Cancel</Button>
      <Button className={styles.updateButton} onClick={this._SubmitUpdate}>Update</Button>
</div>


</div>

  }
 {this.state.toggleIsOverlayVisible && (
<Overlay onClick={this.handleIsOverlayVisible}>
          <div className={styles.redbtn} >
            <p>{this.ErrorMsg}</p>
          </div>
        </Overlay> 
   )}
{this.state.toggleIsOverlayVisible && (
<div>
<div >
      <Snackbar open={this.state.toggleIsOverlayVisible} autoHideDuration={6000} onClose={this.handleIsOverlayVisible}>
        <Alert  severity={this.state.ErrorMsgtype}>
        {this.ErrorMsg}
        </Alert>
      </Snackbar>      
    </div>
</div>
  )}
     </div>
    );
  }
}
